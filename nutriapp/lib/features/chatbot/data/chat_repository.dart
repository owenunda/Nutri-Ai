import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.n8nChat,
        data: {'message': message},
      );
      final data = response.data?['data'];
      return _extractText(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error de conexión con el servidor';
      throw Exception(message);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  String _extractText(dynamic data) {
    if (data == null) return 'Sin respuesta';
    if (data is String) return data;
    if (data is Map) {
      for (final key in ['output', 'response', 'message', 'text', 'reply']) {
        if (data[key] is String && (data[key] as String).isNotEmpty) {
          return data[key] as String;
        }
      }
    }
    return data.toString();
  }
}
