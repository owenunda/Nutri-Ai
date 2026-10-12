import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/presentation/widgets/add_food_sheet.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';

class _RepoFalso extends MealRepository {
  final added = <(int, double, MealType)>[];
  final deleted = <int>[];

  @override
  Future<int> addFood({required int foodId, required double portions, required MealType type, DateTime? now}) async {
    added.add((foodId, portions, type));
    return 77;
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

final _tilapia = FoodModel(
  foodId: 3, name: 'Tilapia', caloriesPerUnit: 96, baseUnit: '100 G', isGlobal: true, isActive: true,
);

Future<_RepoFalso> _open(WidgetTester tester, {DateTime? at, MealType? initial}) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showAddFoodSheet(
            context, _tilapia,
            initialType: initial,
            repository: repo,
            clock: () => at ?? DateTime(2026, 10, 12, 13),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('preselecciona la comida según la hora', (tester) async {
    await _open(tester, at: DateTime(2026, 10, 12, 8));
    expect(find.text('Agregar a Desayuno'), findsOneWidget);
  });

  testWidgets('respeta la comida con la que se abrió', (tester) async {
    await _open(tester, initial: MealType.snack);
    expect(find.text('Agregar a Snack'), findsOneWidget);
  });

  testWidgets('las porciones cambian de media en media con su cálculo', (tester) async {
    await _open(tester);
    expect(find.text('1 porción · 100 g · 96 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Más'));
    await tester.pump();
    expect(find.text('1½ porciones · 150 g · 144 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Menos'));
    await tester.tap(find.byTooltip('Menos'));
    await tester.pump();
    expect(find.text('½ porción · 50 g · 48 kcal'), findsOneWidget);

    // No baja de media porción.
    await tester.tap(find.byTooltip('Menos'));
    await tester.pump();
    expect(find.text('½ porción · 50 g · 48 kcal'), findsOneWidget);
  });

  testWidgets('guarda con el tipo elegido y avisa', (tester) async {
    final revision = MealLogState.instance.revision;
    final repo = await _open(tester);

    await tester.tap(find.text('Cena'));
    await tester.pump();
    await tester.tap(find.text('Agregar a Cena'));
    await tester.pumpAndSettle();

    expect(repo.added.single, (3, 1.0, MealType.dinner));
    expect(MealLogState.instance.revision, revision + 1);
    expect(find.text('Agregado a Cena · 96 kcal'), findsOneWidget);
  });

  testWidgets('Deshacer borra lo que se acaba de agregar', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text('Agregar a Almuerzo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(repo.deleted.single, 77);
  });
}
