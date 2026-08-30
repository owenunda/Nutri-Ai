import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/chatbot/data/message_composer.dart';
import 'package:nutriapp/features/nutrition/data/models/fridge_item_model.dart';

FridgeItemModel item(String name, double quantity, String unit) =>
    FridgeItemModel(fridgeItemId: 1, name: name, quantity: quantity, unit: unit);

void main() {
  group('buildMessageWithFoods', () {
    test('devuelve el mensaje sin cambios cuando no hay alimentos', () {
      expect(buildMessageWithFoods('Hazme una cena', []), 'Hazme una cena');
    });

    test('recorta el mensaje cuando no hay alimentos', () {
      expect(buildMessageWithFoods('  Hazme una cena  ', []), 'Hazme una cena');
    });

    test('agrega los alimentos seleccionados al final del mensaje', () {
      final message = buildMessageWithFoods('Hazme una cena', [
        item('arroz', 200, 'g'),
      ]);

      expect(message, 'Hazme una cena\n\nTengo estos alimentos: 200 g de arroz.');
    });

    test('omite la unidad cuando el alimento se cuenta por unidades', () {
      final message = buildMessageWithFoods('Desayuno', [
        item('huevo', 3, 'unidad'),
      ]);

      expect(message, contains('3 huevo.'));
    });

    test('omite la cantidad cuando es cero', () {
      final message = buildMessageWithFoods('Desayuno', [
        item('cebolla', 0, 'g'),
      ]);

      expect(message, contains('Tengo estos alimentos: cebolla.'));
    });

    test('separa varios alimentos con comas', () {
      final message = buildMessageWithFoods('Almuerzo', [
        item('arroz', 200, 'g'),
        item('huevo', 3, 'unidad'),
        item('cebolla', 0, 'g'),
      ]);

      expect(
        message,
        'Almuerzo\n\nTengo estos alimentos: 200 g de arroz, 3 huevo, cebolla.',
      );
    });

    test('escribe las cantidades enteras sin decimales', () {
      final message = buildMessageWithFoods('Cena', [item('leche', 1.5, 'l')]);

      expect(message, contains('1.5 l de leche'));
    });

    test('usa solo los alimentos cuando el mensaje viene vacío', () {
      final message = buildMessageWithFoods('  ', [item('arroz', 200, 'g')]);

      expect(message, 'Tengo estos alimentos: 200 g de arroz.');
    });
  });
}
