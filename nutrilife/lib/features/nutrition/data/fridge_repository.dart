import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import 'models/fridge_item_model.dart';

class FridgeRepository {
  final Dio _dio;

  FridgeRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<FridgeItemModel>> getFridgeItems() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiRoutes.fridge);
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? 'Error al obtener la nevera');
      }
      final items = data['data']?['items'] as List? ?? [];
      return items
          .cast<Map<String, dynamic>>()
          .map(FridgeItemModel.fromJson)
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Error de conexión con el servidor';
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ocurrió un error inesperado al obtener la nevera: $e');
    }
  }
}
