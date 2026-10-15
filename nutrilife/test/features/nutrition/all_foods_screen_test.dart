import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/fridge_item_model.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/all_foods_screen.dart';
import '../../helpers/l10n_app.dart';

class _FakeFridgeRepository extends FridgeRepository {
  _FakeFridgeRepository() : super(dio: Dio());

  final items = <FridgeItemModel>[
    const FridgeItemModel(
      fridgeItemId: 7,
      foodId: 22,
      name: 'Arroz',
      quantity: 3,
      unit: '1 UNIDAD',
    ),
  ];

  @override
  Future<List<FridgeItemModel>> getFridgeItems() async => [...items];

  @override
  Future<void> updateItem({
    required int fridgeItemId,
    required double quantity,
  }) async {
    final index = items.indexWhere((item) => item.fridgeItemId == fridgeItemId);
    final item = items[index];
    items[index] = FridgeItemModel(
      fridgeItemId: item.fridgeItemId,
      foodId: item.foodId,
      name: item.name,
      quantity: quantity,
      unit: item.unit,
    );
  }

  @override
  Future<void> deleteItem({required int fridgeItemId}) async {
    items.removeWhere((item) => item.fridgeItemId == fridgeItemId);
  }
}

Future<void> _pumpFridge(
  WidgetTester tester,
  _FakeFridgeRepository repository,
) async {
  await tester.pumpWidget(
    l10nApp(
      AllFoodsScreen(showFridge: true, fridgeRepository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('allows increasing, decreasing, and setting the exact quantity', (
    tester,
  ) async {
    final repository = _FakeFridgeRepository();
    await _pumpFridge(tester, repository);

    await tester.tap(find.byTooltip('Editar cantidad de Arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aumentar'));
    await tester.pumpAndSettle();
    expect(repository.items.single.quantity, 4);

    await tester.tap(find.byTooltip('Editar cantidad de Arroz'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fridge-adjust-quantity')),
      '1',
    );
    await tester.tap(find.text('Descontar'));
    await tester.pumpAndSettle();
    expect(repository.items.single.quantity, 3);

    await tester.tap(find.byTooltip('Editar cantidad de Arroz'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fridge-exact-quantity')),
      '5',
    );
    await tester.tap(find.text('Guardar cantidad exacta'));
    await tester.pumpAndSettle();
    expect(repository.items.single.quantity, 5);
  });

  testWidgets('asks for confirmation before removing a fridge item', (
    tester,
  ) async {
    final repository = _FakeFridgeRepository();
    await _pumpFridge(tester, repository);

    await tester.tap(find.byTooltip('Editar cantidad de Arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar de la nevera'));
    await tester.pumpAndSettle();

    expect(find.text('Quitar alimento'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
    await tester.pumpAndSettle();

    expect(repository.items, isEmpty);
    expect(find.textContaining('Tu nevera está vacía'), findsOneWidget);
  });
}
