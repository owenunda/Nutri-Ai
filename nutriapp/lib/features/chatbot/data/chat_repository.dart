import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import 'models/recipe_model.dart';
import 'models/chat_session_model.dart';

class ChatResponse {
  final String text;
  final RecipeModel? recipe;

  const ChatResponse({required this.text, this.recipe});
}

class ChatRepository {
  final Dio _dio;

  ChatRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<ChatResponse> sendMessage(String message) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.n8nChat,
        data: {'message': message},
      );
      final firstLevel = response.data?['data'];

      // n8n now returns the backend session response:
      // { success, message, data: { ..., conversationState: { recipe, media } } }
      if (firstLevel is Map && firstLevel['data'] is Map) {
        final inner = firstLevel['data'] as Map;
        if (inner['conversationState'] is Map) {
          return _parseResponse(inner['conversationState'] as Map);
        }
      }

      return _parseResponse(firstLevel);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Error de conexión con el servidor';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
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

  ChatResponse _parseResponse(dynamic data) {
    if (data == null) return const ChatResponse(text: 'Sin respuesta');

    if (data is Map) {
      // New format: { "recipe": {...}, "media": { "youtube": {...} } }
      if (RecipeModel.isNestedRecipeMap(data)) {
        final recipeMap = data['recipe'] as Map;
        final youtubeMap = data['media']?['youtube'] as Map?;
        final youtube = youtubeMap != null
            ? YoutubeVideoModel.fromMap(youtubeMap)
            : null;
        final recipe = RecipeModel.fromMap(recipeMap, youtube: youtube);
        return ChatResponse(text: recipe.chefReason, recipe: recipe);
      }

      // Old flat format: the map itself is the recipe
      if (RecipeModel.isRecipeMap(data)) {
        final recipe = RecipeModel.fromMap(data);
        return ChatResponse(text: recipe.chefReason, recipe: recipe);
      }

      for (final key in ['output', 'response', 'message', 'text', 'reply']) {
        if (data[key] is String && (data[key] as String).isNotEmpty) {
          return ChatResponse(text: data[key] as String);
        }
      }
    }

    if (data is String && data.isNotEmpty) {
      return ChatResponse(text: data);
    }

    return ChatResponse(text: data.toString());
  }
}
