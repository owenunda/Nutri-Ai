import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/local_date.dart';
import '../domain/meal_type.dart';
import 'models/day_meals.dart';

class MealRepository {
  final Dio _dio;

  MealRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Registra [portions] porciones del alimento en la comida [type] del día
  /// local. Devuelve el id del ítem (para "Deshacer").
  Future<int> addFood({
    required int foodId,
    required double portions,
    required MealType type,
    DateTime? now,
  }) async {
    try {
      final record = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.meals,
        data: {'date': localDateString(now)},
      );
      final recordId = (record.data?['data']?['mealRecordId'] as num).toInt();
      final items = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.mealItems(recordId),
        data: [
          {'food_id': foodId, 'quantity': portions, 'meal_type': type.apiValue}
        ],
      );
      final created = (items.data?['data'] as List).first as Map;
      return (created['detailId'] as num).toInt();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudo registrar la comida');
    }
  }

  Future<void> deleteItem(int detailId) async {
    try {
      await _dio.delete<void>(ApiRoutes.mealItem(detailId));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudo borrar');
    }
  }

  Future<DayMeals> getDay(String date) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.mealsDay,
        queryParameters: {'date': date},
      );
      final data = response.data?['data'];
      return data is Map ? DayMeals.fromJson(data) : DayMeals.empty(date);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudieron cargar tus comidas');
    }
  }
}
