import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/utils/local_date.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/domain/portions.dart';
import 'package:nutrilife/l10n/app_localizations.dart';

final _es = lookupAppLocalizations(const Locale('es'));

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

  group('unidades base', () {
    test('baseAmountOf lee el número de la unidad', () {
      expect(baseAmountOf('100 G'), 100);
      expect(baseAmountOf('100 G COCIDO'), 100);
      expect(baseAmountOf('1 UNIDAD'), 1);
      expect(baseAmountOf('2 grandes'), 2);
      expect(baseAmountOf('nada xd'), 1);
    });

    test('toBaseUnits pasa cantidades naturales a unidades base', () {
      expect(toBaseUnits(300, '100 G'), 3);
      expect(toBaseUnits(1, '2 grandes'), 0.5);
      expect(toBaseUnits(2, '1 UNIDAD'), 2);
    });

    test('quantityLabel conserva el detalle de la unidad', () {
      expect(quantityLabel(3, '100 G COCIDO'), '300 g cocido');
    });
  });

  group('mealItemLabel', () {
    test('medias porciones exactas dicen porciones', () {
      expect(mealItemLabel(1.5, '100 G', _es), '1½ porciones · 150 g');
      expect(mealItemLabel(1, '100 G COCIDO', _es), '1 porción · 100 g cocido');
    });

    test('0,75 no se redondea a media porción', () {
      expect(mealItemLabel(0.75, '100 G', _es), '75 g');
      expect(mealItemLabel(0.17, '1 UNIDAD', _es), '0,17 unidad');
    });
  });
}
