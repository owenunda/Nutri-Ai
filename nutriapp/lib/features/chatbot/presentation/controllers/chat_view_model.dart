import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/rate_limit_state.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _typingTimer;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearMessages() {
    _typingTimer?.cancel();
    _messages.clear();
    _isLoading = false;
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
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _typingTimer?.cancel();

    _messages.add(ChatMessageModel(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(text.trim());
      if (reply.recipe != null) {
        _messages.add(ChatMessageModel(
          text: reply.text,
          isUser: false,
          timestamp: DateTime.now(),
          recipeData: reply.recipe,
        ));
        notifyListeners();
      } else {
        _startTypewriter(reply.text);
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
      notifyListeners();
    }
  }

  void _startTypewriter(String fullText) {
    final msg = ChatMessageModel.animating(
      text: fullText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    notifyListeners();

    int charIndex = 0;
    // 2 chars per tick at 18ms ≈ 110 chars/s — natural typing feel
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      charIndex = (charIndex + 2).clamp(0, fullText.length);
      msg.displayedText = fullText.substring(0, charIndex);
      notifyListeners();
      if (charIndex >= fullText.length) timer.cancel();
    });
  }
}
