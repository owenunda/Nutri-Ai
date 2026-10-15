import 'package:dio/dio.dart';
import '../../../core/l10n/l10n.dart';
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
        throw Exception(responseData?['message'] ?? currentL10n.nutritionErrorLoadFoods);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? currentL10n.nutritionErrorServerConnection;
      throw Exception(message);
    } catch (e) {
      throw Exception(currentL10n.nutritionErrorUnexpectedLoadFoods(e.toString()));
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
        throw Exception(responseData?['message'] ?? currentL10n.nutritionErrorRegisterFood);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? currentL10n.nutritionErrorRegisterFoodServer;
      throw Exception(message);
    } catch (e) {
      throw Exception(currentL10n.nutritionErrorUnexpectedRegisterFood(e.toString()));
    }
  }
}
