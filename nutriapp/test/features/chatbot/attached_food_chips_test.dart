import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/chatbot/presentation/widgets/attached_food_chips.dart';
import 'package:nutriapp/features/nutrition/data/models/fridge_item_model.dart';

const _banana = FridgeItemModel(
  fridgeItemId: 4,
  foodId: 11,
  name: 'Banana',
  quantity: 0,
  unit: 'unidad',
  caloriesPerUnit: 89,
  baseUnit: '100 G',
);

const _arroz = FridgeItemModel(
  fridgeItemId: 5,
  foodId: 12,
  name: 'Arroz',
  quantity: 200,
  unit: 'g',
  caloriesPerUnit: 130,
  baseUnit: '100 G',
);

Future<void> pump(WidgetTester tester, List<FridgeItemModel> foods) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AttachedFoodChips(foods: foods)),
  ));
}

void main() {
  testWidgets('pinta una etiqueta por alimento', (tester) async {
    await pump(tester, [_banana, _arroz]);

    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Arroz · 200 g'), findsOneWidget);
  });

  testWidgets('omite la cantidad cuando no hay', (tester) async {
    await pump(tester, [_banana]);

    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('no pinta nada sin alimentos', (tester) async {
    await pump(tester, []);

    expect(find.byType(Wrap), findsNothing);
  });
}
