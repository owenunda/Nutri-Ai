import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/nutrition/data/models/fridge_item_model.dart';

void main() {
  group('FridgeItemModel.fromJson', () {
    test('mapea los detalles del alimento', () {
      final item = FridgeItemModel.fromJson({
        'fridgeItemId': 4,
        'foodId': 11,
        'name': 'banana',
        'quantity': 2,
        'unit': 'unidad',
        'caloriesPerUnit': 89,
        'baseUnit': '100 g',
      });

      expect(item.foodId, 11);
      expect(item.caloriesPerUnit, 89);
      expect(item.baseUnit, '100 g');
    });

    test('lee calorías que llegan como texto', () {
      final item = FridgeItemModel.fromJson({
        'fridgeItemId': 4,
        'name': 'banana',
        'quantity': 0,
        'unit': 'unidad',
        'caloriesPerUnit': '89.50',
      });

      expect(item.caloriesPerUnit, 89.5);
    });

    test('sobrevive a una respuesta sin los campos nuevos', () {
      final item = FridgeItemModel.fromJson({
        'fridgeItemId': 4,
        'name': 'banana',
        'quantity': 2,
        'unit': 'unidad',
      });

      expect(item.name, 'banana');
      expect(item.foodId, 0);
      expect(item.caloriesPerUnit, 0);
      expect(item.baseUnit, '');
    });
  });
}
