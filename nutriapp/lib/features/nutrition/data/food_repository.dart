import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'models/food_model.dart';

class FoodRepository {
  final Dio _dio;

  FoodRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<FoodModel>> getFoods() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/food');
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        final List<dynamic> foodsJson = responseData['data']['foods'] ?? [];
        return foodsJson.map((json) => FoodModel.fromJson(json)).toList();
      } else {
        throw Exception(responseData?['message'] ?? 'Error al obtener alimentos');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error de conexión con el servidor';
      throw Exception(message);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al obtener los alimentos: $e');
    }
  }

  Future<FoodModel> createFood({
    required String name,
    required double caloriesPerUnit,
    required String baseUnit,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/food',
        data: {
          'name': name,
          'calories_per_unit': caloriesPerUnit,
          'base_unit': baseUnit,
        },
      );
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        final foodId = responseData['data']['foodId'] ?? 0;
        return FoodModel(
          foodId: foodId,
          name: name,
          caloriesPerUnit: caloriesPerUnit,
          baseUnit: baseUnit,
          isGlobal: false,
          isActive: true,
        );
      } else {
        throw Exception(responseData?['message'] ?? 'Error al registrar el alimento');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al registrar el alimento en el servidor';
      throw Exception(message);
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al registrar el alimento: $e');
    }
  }
}
