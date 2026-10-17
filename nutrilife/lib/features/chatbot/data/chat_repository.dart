import 'package:dio/dio.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/rate_limit_state.dart';
import 'models/chat_actions_model.dart';
import 'models/chat_message_model.dart';
import 'models/chat_quota_model.dart';
import 'models/recipe_model.dart';
import 'models/chat_session_model.dart';

/// Valores del campo `type` del envelope que devuelve el flujo de n8n.
enum ChatResponseType { recipe, recipeModified, answer, chat }

ChatResponseType _chatResponseTypeFrom(String? raw) {
  switch (raw) {
    case 'RECIPE':
      return ChatResponseType.recipe;
    case 'RECIPE_MODIFIED':
      return ChatResponseType.recipeModified;
    case 'ANSWER':
      return ChatResponseType.answer;
    default:
      return ChatResponseType.chat;
  }
}

class ChatResponse {
  final ChatResponseType type;
  final String text;
  final RecipeModel? recipe;
  final ChatActions? actions;
  final ChatQuota? quota;

  const ChatResponse({
    required this.type,
    required this.text,
    this.recipe,
    this.actions,
    this.quota,
  });

  bool get isModification => type == ChatResponseType.recipeModified;
}

class ChatRepository {
  final Dio _dio;

  /// El flujo encadena dos llamadas a un LLM más varias al backend,
  /// así que no cabe en el receiveTimeout global de 15s.
  static const Duration _chatTimeout = Duration(seconds: 90);

  ChatRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<ChatResponse> sendMessage(
    String message, {
    List<int> fridgeItemIds = const [],
    List<int> foodIds = const [],
  }) async {
    final Response<Map<String, dynamic>> response;

    try {
      response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.n8nChat,
        data: {
          'message': message,
          // El backend los relee de la nevera; aquí solo viajan los ids.
          if (fridgeItemIds.isNotEmpty) 'fridgeItemIds': fridgeItemIds,
          // Alimentos comunes adjuntados sin pasar por la nevera.
          if (foodIds.isNotEmpty) 'foodIds': foodIds,
        },
        options: Options(
          receiveTimeout: _chatTimeout,
          sendTimeout: _chatTimeout,
        ),
      );
    } on DioException catch (e) {
      final quotaError = _quotaExceededFrom(e.response);
      if (quotaError != null) throw quotaError;
      if (e.error is RateLimitException) {
        final r = e.error as RateLimitException;
        throw RateLimitException(
          retryAfterSeconds: r.retryAfterSeconds,
          limit: r.limit,
        );
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception(currentL10n.chatErrorTimeout);
      }
      final msg = e.response?.data?['message'] ??
          currentL10n.chatErrorServerConnection;
      throw Exception(msg);
    }

    // El backend envuelve la respuesta de n8n:
    // { success, message, data: { type, message, recipe, media, session } }
    final envelope = response.data?['data'];
    if (envelope is! Map) {
      throw Exception(currentL10n.chatErrorUnexpectedResponse);
    }

    try {
      return _parseEnvelope(envelope);
    } catch (e) {
      throw Exception(currentL10n.chatErrorReadReply(e.toString()));
    }
  }

  /// Mensajes que le quedan hoy. Null si el backend no responde o no la sabe:
  /// el chat funciona igual, sin contador.
  Future<ChatQuota?> getQuota() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiRoutes.chatQuota);
      return ChatQuota.fromMap(response.data?['data']);
    } on DioException {
      return null;
    }
  }

  static const _quotaErrorCodes = {'CHAT_DAILY_LIMIT', 'CHAT_FAIR_USE_LIMIT'};

  /// El 429 del límite del día trae la cuota en `data.quota`. El del límite
  /// por minuto no, y sigue su camino de siempre.
  ChatQuotaExceededException? _quotaExceededFrom(Response? response) {
    if (response?.statusCode != 429) return null;
    final body = response?.data;
    if (body is! Map) return null;
    final code = (body['error'] as Map?)?['code'];
    if (!_quotaErrorCodes.contains(code)) return null;
    final quota = ChatQuota.fromMap((body['data'] as Map?)?['quota']) ??
        ChatQuota(
          unlimited: code == 'CHAT_FAIR_USE_LIMIT',
          remaining: 0,
          exhausted: true,
        );
    return ChatQuotaExceededException(quota);
  }

  Future<List<ChatSessionModel>> getSessions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiRoutes.chatSessions);
      final list = response.data?['data'] as List? ?? [];
      return list
          .cast<Map<String, dynamic>>()
          .map(ChatSessionModel.fromMap)
          .toList();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? currentL10n.chatErrorLoadHistory;
      throw Exception(msg);
    } catch (e) {
      throw Exception(currentL10n.chatErrorUnexpected(e.toString()));
    }
  }

  /// Id de la sesión activa, o null si el usuario no tiene ninguna abierta.
  Future<int?> getActiveSessionId() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiRoutes.chatActiveSession);
      final data = response.data?['data'] as Map?;
      if (data?['hasActiveSession'] != true) return null;
      return ((data?['session'] as Map?)?['sessionId'] as num?)?.toInt();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? currentL10n.chatErrorLoadSession;
      throw Exception(msg);
    }
  }

  /// Mensajes de una sesión, listos para pintar.
  ///
  /// La receta vive en el conversation_state y solo en su última versión, así
  /// que la tarjeta se pega al último mensaje que generó receta (según su
  /// metadata). Los mensajes guardados antes de que existiera metadata no
  /// dicen su tipo: para esos se usa el último mensaje del bot.
  Future<List<ChatMessageModel>> getSessionMessages(int sessionId) async {
    final Map? data;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.chatSessionMessages(sessionId),
      );
      data = response.data?['data'] as Map?;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          currentL10n.chatErrorLoadConversation;
      throw Exception(msg);
    }

    final state = (data?['session'] as Map?)?['conversationState'] as Map?;
    final recipeMap = state?['recipe'];
    final youtubeMap = (state?['media'] as Map?)?['youtube'];
    final recipe = recipeMap is Map
        ? RecipeModel.fromMap(
            recipeMap,
            youtube:
                youtubeMap is Map ? YoutubeVideoModel.fromMap(youtubeMap) : null,
          )
        : null;

    final rows = (data?['messages'] as List? ?? []).whereType<Map>().toList();
    Map? metadataOf(Map row) =>
        row['metadata'] is Map ? row['metadata'] as Map : null;
    final lastRecipeIndex = rows.lastIndexWhere((m) {
      final type = metadataOf(m)?['type'];
      return type == 'RECIPE' || type == 'RECIPE_MODIFIED';
    });
    final recipeIndex = lastRecipeIndex != -1
        ? lastRecipeIndex
        : rows.lastIndexWhere((m) => m['role'] == 'ASSISTANT');

    return [
      for (final (i, row) in rows.indexed)
        ChatMessageModel(
          text: row['content'] as String? ?? '',
          isUser: row['role'] == 'USER',
          timestamp: DateTime.tryParse(row['createdAt'] as String? ?? '')
                  ?.toLocal() ??
              DateTime.now(),
          recipeData: i == recipeIndex ? recipe : null,
          actions: ChatActions.fromMap(metadataOf(row)?['actions']),
        ),
    ];
  }

  /// Retoma una sesión anterior: el backend cierra la activa y abre esta.
  Future<void> activateSession(int sessionId) async {
    try {
      await _dio.put<void>(ApiRoutes.chatSessionActivate(sessionId));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          currentL10n.chatErrorOpenConversation;
      throw Exception(msg);
    }
  }

  Future<void> closeSession() async {
    try {
      await _dio.put<void>(ApiRoutes.chatSessionClose);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? currentL10n.chatErrorCloseSession;
      throw Exception(msg);
    } catch (e) {
      throw Exception(currentL10n.chatErrorUnexpected(e.toString()));
    }
  }

  ChatResponse _parseEnvelope(Map envelope) {
    final type = _chatResponseTypeFrom(envelope['type'] as String?);
    final message = (envelope['message'] as String?)?.trim() ?? '';
    final quota = ChatQuota.fromMap(envelope['quota']);

    // ANSWER y CHAT vienen sin receta: la clave existe pero vale null.
    final recipeMap = envelope['recipe'];
    if (recipeMap is! Map) {
      return ChatResponse(
        type: type,
        text: message.isEmpty ? currentL10n.chatNoReply : message,
        actions: ChatActions.fromMap(envelope['actions']),
        quota: quota,
      );
    }

    final youtubeMap = (envelope['media'] as Map?)?['youtube'];
    final youtube =
        youtubeMap is Map ? YoutubeVideoModel.fromMap(youtubeMap) : null;
    final recipe = RecipeModel.fromMap(recipeMap, youtube: youtube);

    return ChatResponse(
      type: type,
      text: message.isNotEmpty ? message : recipe.chefReason,
      recipe: recipe,
      quota: quota,
    );
  }
}
