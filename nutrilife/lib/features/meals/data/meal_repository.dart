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
    final ids = await addFoods(items: [(foodId: foodId, quantity: portions)], type: type, now: now);
    return ids.first;
  }

  /// Registra varios alimentos de una vez (p. ej. los ingredientes de una
  /// receta). El backend los inserta en una transacción. Devuelve los ids.
  Future<List<int>> addFoods({
    required List<({int foodId, double quantity})> items,
    required MealType type,
    DateTime? now,
  }) async {
    try {
      final record = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.meals,
        data: {'date': localDateString(now)},
      );
      final recordId = (record.data?['data']?['mealRecordId'] as num).toInt();
      final created = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.mealItems(recordId),
        data: [
          for (final item in items)
            {'food_id': item.foodId, 'quantity': item.quantity, 'meal_type': type.apiValue}
        ],
      );
      return (created.data?['data'] as List)
          .map((e) => ((e as Map)['detailId'] as num).toInt())
          .toList();
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
