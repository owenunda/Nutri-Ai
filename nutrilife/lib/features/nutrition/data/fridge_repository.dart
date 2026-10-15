import 'package:dio/dio.dart';
import '../../../core/l10n/l10n.dart';
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
        throw Exception(data?['message'] ?? currentL10n.nutritionErrorLoadFridge);
      }
      final items = data['data']?['items'] as List? ?? [];
      return items
          .cast<Map<String, dynamic>>()
          .map(FridgeItemModel.fromJson)
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ??
          currentL10n.nutritionErrorServerConnection;
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(currentL10n.nutritionErrorUnexpectedLoadFridge(e.toString()));
    }
  }

  /// Agrega [quantity] [unit] del alimento [foodId] a la nevera del usuario.
  /// Devuelve el ítem creado. Si el alimento ya está, el backend puede
  /// sumar la cantidad o devolverlo; aquí solo propagamos la respuesta.
  Future<FridgeItemModel> addItem({
    required int foodId,
    required double quantity,
    required String unit,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiRoutes.fridge}/items',
        data: {
          'foodId': foodId,
          'quantity': quantity,
          'unit': unit,
        },
      );
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? currentL10n.nutritionErrorAddToFridge);
      }
      final raw = data['data'];
      if (raw is Map<String, dynamic>) {
        return FridgeItemModel.fromJson(raw);
      }
      // Si el backend no devuelve el ítem, recargamos la nevera completa.
      final all = await getFridgeItems();
      return all.firstWhere(
        (i) => i.foodId == foodId,
        orElse: () => FridgeItemModel(
          fridgeItemId: 0,
          foodId: foodId,
          name: '',
          quantity: quantity,
          unit: unit,
        ),
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ??
          currentL10n.nutritionErrorServerConnection;
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(currentL10n.nutritionErrorAddToFridgeDetail(e.toString()));
    }
  }

  /// Reemplaza la cantidad disponible de un ítem de la nevera.
  Future<void> updateItem({
    required int fridgeItemId,
    required double quantity,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiRoutes.fridge}/items/$fridgeItemId',
        data: {'quantity': quantity},
      );
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? currentL10n.nutritionErrorUpdateAmount);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ??
          currentL10n.nutritionErrorServerConnection;
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(currentL10n.nutritionErrorUpdateAmountDetail(e.toString()));
    }
  }

  /// Quita un ítem de la nevera.
  Future<void> deleteItem({required int fridgeItemId}) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '${ApiRoutes.fridge}/items/$fridgeItemId',
      );
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? currentL10n.nutritionErrorRemoveFromFridge);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ??
          currentL10n.nutritionErrorServerConnection;
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(currentL10n.nutritionErrorRemoveFromFridgeDetail(e.toString()));
    }
  }

  /// Variante batch: agrega varios ítems a la nevera en paralelo.
  /// Devuelve la lista de errores por foodId; los que tuvieron éxito se
  /// omiten para que el caller pueda mostrar el resumen.
  Future<Map<int, String>> addItems(
    List<({int foodId, double quantity, String unit})> entries,
  ) async {
    final results = await Future.wait(
      entries.map((e) async {
        try {
          await addItem(
            foodId: e.foodId,
            quantity: e.quantity,
            unit: e.unit,
          );
          return MapEntry<int, String>(e.foodId, '');
        } catch (err) {
          return MapEntry<int, String>(e.foodId, err.toString());
        }
      }),
    );
    return Map.fromEntries(results);
  }
}
