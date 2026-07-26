import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
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

  const ChatResponse({
    required this.type,
    required this.text,
    this.recipe,
  });

  bool get isModification => type == ChatResponseType.recipeModified;
}

class ChatRepository {
  final Dio _dio;

  /// El flujo encadena dos llamadas a un LLM más varias al backend,
  /// así que no cabe en el receiveTimeout global de 15s.
  static const Duration _chatTimeout = Duration(seconds: 90);

  ChatRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<ChatResponse> sendMessage(String message) async {
    final Response<Map<String, dynamic>> response;

    try {
      response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.n8nChat,
        data: {'message': message},
        options: Options(
          receiveTimeout: _chatTimeout,
          sendTimeout: _chatTimeout,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('El chef se está tomando su tiempo. Intenta de nuevo.');
      }
      final msg = e.response?.data?['message'] ??
          'Error de conexión con el servidor';
      throw Exception(msg);
    }

    // El backend envuelve la respuesta de n8n:
    // { success, message, data: { type, message, recipe, media, session } }
    final envelope = response.data?['data'];
    if (envelope is! Map) {
      throw Exception('Respuesta inesperada del servidor');
    }

    try {
      return _parseEnvelope(envelope);
    } catch (e) {
      throw Exception('No se pudo leer la respuesta del chef: $e');
    }
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
      final msg = e.response?.data?['message'] ?? 'Error al obtener el historial';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  Future<void> closeSession() async {
    try {
      await _dio.put<void>(ApiRoutes.chatSessionClose);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Error al cerrar la sesión';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  ChatResponse _parseEnvelope(Map envelope) {
    final type = _chatResponseTypeFrom(envelope['type'] as String?);
    final message = (envelope['message'] as String?)?.trim() ?? '';

    // ANSWER y CHAT vienen sin receta: la clave existe pero vale null.
    final recipeMap = envelope['recipe'];
    if (recipeMap is! Map) {
      return ChatResponse(
        type: type,
        text: message.isEmpty ? 'Sin respuesta' : message,
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
    );
  }
}
