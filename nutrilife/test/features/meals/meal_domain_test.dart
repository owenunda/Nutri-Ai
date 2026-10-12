import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/utils/local_date.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/domain/portions.dart';

void main() {
  test('localDateString usa la fecha local con ceros', () {
    expect(localDateString(DateTime(2026, 3, 7, 23, 50)), '2026-03-07');
  });

  group('MealType.forTime', () {
    test('antes de las 11 es desayuno', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 10, 59)), MealType.breakfast);
    });
    test('de 11 a 15:59 es almuerzo', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 11)), MealType.lunch);
      expect(MealType.forTime(DateTime(2026, 1, 1, 15, 59)), MealType.lunch);
    });
    test('desde las 16 es cena', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 16)), MealType.dinner);
    });
  });

  test('MealType.fromApi cae en snack si no lo conoce', () {
    expect(MealType.fromApi('LUNCH'), MealType.lunch);
    expect(MealType.fromApi('???'), MealType.snack);
    expect(MealType.fromApi(null), MealType.snack);
  });

  group('porciones', () {
    test('etiqueta con medios', () {
      expect(portionsLabel(0.5), '½');
      expect(portionsLabel(1), '1');
      expect(portionsLabel(1.5), '1½');
    });
    test('cantidad en gramos cuando la unidad es numérica', () {
      expect(quantityLabel(1.5, '100 G'), '150 g');
      expect(quantityLabel(2, '250 ML'), '500 ml');
    });
    test('cantidad en la unidad cuando no es numérica', () {
      expect(quantityLabel(1.5, '1 UNIDAD'), '1½ unidad');
      expect(quantityLabel(1, 'TAZA'), '1 taza');
    });
    test('kcal redondeadas', () {
      expect(caloriesFor(1.5, 96), 144);
    });
  });
}
