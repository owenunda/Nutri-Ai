import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import 'models/recipe_model.dart';

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
      final data = response.data?['data'];
      return _parseResponse(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Error de conexión con el servidor';
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
