import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/rate_limit_state.dart';
import '../../../../core/state/bot_mood_state.dart';
import '../../../bot/domain/bot_mood.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_actions_model.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/recipe_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _typingTimer;

  /// Un 401 manda al login y destruye el chat aunque haya una respuesta en
  /// camino: lo que llegue después no debe tocar la pantalla.
  bool _disposed = false;
  int? _currentSessionId;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sesión cuyos mensajes están en pantalla. Null en un chat nuevo hasta que
  /// se cargue desde el historial.
  int? get currentSessionId => _currentSessionId;

  void clearMessages() {
    _typingTimer?.cancel();
    _messages.clear();
    _isLoading = false;
    _errorMessage = null;
    _currentSessionId = null;
    notifyListeners();
  }

  /// Repinta la conversación que quedó activa la última vez.
  Future<void> loadActiveSession() async {
    try {
      final sessionId = await _repository.getActiveSessionId();
      if (sessionId == null) return;
      final history = await _repository.getSessionMessages(sessionId);
      // Si el usuario ya escribió mientras cargaba, su chat manda.
      if (_messages.isNotEmpty || _isLoading) return;
      _showHistory(sessionId, history);
    } catch (e) {
      // Sin historial el chat sigue siendo usable: arranca vacío.
      debugPrint('ChatViewModel.loadActiveSession falló: $e');
    }
  }

  /// Abre una conversación del historial y la deja lista para continuarla.
  Future<void> openSession(int sessionId) async {
    // Con una respuesta en camino, cambiar de chat la soltaría en el chat
    // equivocado.
    if (_isLoading) return;
    try {
      await _repository.activateSession(sessionId);
      final history = await _repository.getSessionMessages(sessionId);
      _showHistory(sessionId, history);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _showHistory(int sessionId, List<ChatMessageModel> history) {
    _typingTimer?.cancel();
    _messages
      ..clear()
      ..addAll(history);
    _currentSessionId = sessionId;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteChat() async {
    try {
      await _repository.closeSession();
    } catch (_) {
      // session may not exist; clear locally regardless
    }
    clearMessages();
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> sendMessage(
    String text, {
    List<FridgeItemModel> foods = const [],
  }) async {
    final message = text.trim();
    // Adjuntar alimentos sin escribir nada es una petición válida.
    if (message.isEmpty && foods.isEmpty) return;

    _typingTimer?.cancel();

    _messages.add(ChatMessageModel(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      attachedFoods: foods,
    ));
    _isLoading = true;
    _errorMessage = null;
    BotMoodState.instance.hold(BotMood.thinking);
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(
        message,
        fridgeItemIds: [for (final f in foods) if (f.isFromFridge) f.fridgeItemId],
        foodIds: [for (final f in foods) if (!f.isFromFridge) f.foodId],
      );
      if (reply.recipe != null) {
        _messages.add(ChatMessageModel(
          text: reply.text,
          isUser: false,
          timestamp: DateTime.now(),
          recipeData: reply.recipe,
        ));
        notifyListeners();
      } else {
        _startTypewriter(reply.text, actions: reply.actions);
      }
    } catch (e, stackTrace) {
      if (e is RateLimitException) {
        final mins = (e.retryAfterSeconds / 60).ceil();
        final friendly = mins <= 1
            ? 'Espera un momento, alcanzaste el límite de mensajes por minuto'
            : 'Espera unos $mins minutos, alcanzaste el límite de mensajes';
        _startTypewriter(friendly);
        return;
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Sin esto el error real queda invisible: el usuario solo ve el texto
      // genérico y no hay rastro de qué falló.
      debugPrint('ChatViewModel.sendMessage falló: $_errorMessage');
      debugPrintStack(stackTrace: stackTrace);
      _startTypewriter(
        kDebugMode
            ? 'Error: $_errorMessage'
            : 'Lo siento, ocurrió un error. Intenta de nuevo.',
      );
    } finally {
      _isLoading = false;
      BotMoodState.instance.hold(BotMood.idle);
      // hold(idle) va antes del pulse: pulse solo se aplica sobre idle.
      // Sin el guard del rate limit, agotar el limite haria guinar al bot,
      // porque esa rama hace return sin poner _errorMessage.
      if (_errorMessage == null && !DioClient.rateLimit.isExhausted) {
        BotMoodState.instance.pulse(BotMood.pleased);
      }
      notifyListeners();
    }
  }

  /// Receta a la que se refiere el mensaje [index]: la más reciente antes de
  /// él. Al reabrir un chat solo la última versión de la receta tiene tarjeta,
  /// así que si no hay ninguna antes se usa la última de la conversación.
  static RecipeModel? recipeBefore(List<ChatMessageModel> messages, int index) {
    for (var i = index; i >= 0; i--) {
      if (messages[i].recipeData != null) return messages[i].recipeData;
    }
    for (var i = messages.length - 1; i > index; i--) {
      if (messages[i].recipeData != null) return messages[i].recipeData;
    }
    return null;
  }

  void _startTypewriter(String fullText, {ChatActions? actions}) {
    // Un Timer creado tras el dispose nadie lo cancelaría.
    if (_disposed) return;
    final msg = ChatMessageModel.animating(
      text: fullText,
      isUser: false,
      timestamp: DateTime.now(),
      actions: actions,
    );
    _messages.add(msg);
    notifyListeners();

    int charIndex = 0;
    // 2 chars per tick at 18ms ≈ 110 chars/s — natural typing feel
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      charIndex = (charIndex + 2).clamp(0, fullText.length);
      // Los emoji ocupan dos unidades UTF-16: cortar entre ellas deja un
      // surrogate suelto y Flutter revienta al pintar el texto.
      if (charIndex < fullText.length &&
          _isHighSurrogate(fullText.codeUnitAt(charIndex - 1))) {
        charIndex++;
      }
      msg.displayedText = fullText.substring(0, charIndex);
      notifyListeners();
      if (charIndex >= fullText.length) timer.cancel();
    });
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}
