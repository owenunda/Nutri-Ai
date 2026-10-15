import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/nutrition/presentation/controllers/foods_view_model.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/home/presentation/widgets/today_meals_section.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';

import '../../helpers/l10n_app.dart';

class _RepoFalso extends MealRepository {
  _RepoFalso({this.initialCalories = 144});

  final int initialCalories;
  int loads = 0;
  final deleted = <int>[];
  final consumed = <({int foodId, double quantity, MealType type})>[];
  String? lastDate;

  @override
  Future<DayMeals> getDay(String date) async {
    loads++;
    lastDate = date;
    final meals = <String, dynamic>{
      'LUNCH': {
        'totalCalories': initialCalories,
        'items': [
          {
            'detailId': 5,
            'foodId': 3,
            'name': 'Tilapia',
            'baseUnit': '100 G',
            'quantity': 1.5,
            'calories': 144,
          },
        ],
      },
    };
    for (final type in MealType.values) {
      final items = consumed.where((item) => item.type == type).toList();
      if (items.isEmpty) continue;
      meals[type.apiValue] = {
        'totalCalories': items.length * 100,
        'items': [
          for (var index = 0; index < items.length; index++)
            {
              'detailId': 10 + index,
              'foodId': items[index].foodId,
              'name': switch (items[index].foodId) {
                20 => 'Avena',
                21 => 'Arroz',
                22 => 'Pollo',
                _ => 'Alimento',
              },
              'baseUnit': '100 G',
              'quantity': items[index].quantity,
              'calories': 100,
            },
        ],
      };
    }
    return DayMeals.fromJson({
      'date': date,
      'totalCalories': initialCalories + consumed.length * 100,
      'meals': meals,
    });
  }

  @override
  Future<int> addFood({
    required int foodId,
    required double portions,
    required MealType type,
    DateTime? now,
  }) async {
    consumed.add((foodId: foodId, quantity: portions, type: type));
    return consumed.length;
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

class _ProgressRepoFalso extends ProgressRepository {
  _ProgressRepoFalso(this.dailyLimit);

  final int? dailyLimit;

  @override
  Future<int?> fetchDailyLimit({DateTime? now}) async => dailyLimit;
}

Future<_RepoFalso> _pump(
  WidgetTester tester, {
  int dailyLimit = 2000,
  int initialCalories = 144,
  Locale locale = const Locale('es'),
}) async {
  final repo = _RepoFalso(initialCalories: initialCalories);
  await tester.pumpWidget(
    l10nApp(
      Scaffold(
        body: SingleChildScrollView(
          child: TodayMealsSection(
            repository: repo,
            progressRepository: _ProgressRepoFalso(dailyLimit),
            clock: () => DateTime(2026, 10, 12, 21),
          ),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('muestra lo registrado hoy y lo que falta', (tester) async {
    final repo = await _pump(tester);

    expect(repo.lastDate, '2026-10-12');
    expect(find.text('Tilapia • 144 kcal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-calories-card')),
        matching: find.text(
          'Te faltan 1.856 kcal para cumplir tu objetivo de hoy.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Aún no registrada'), findsNWidgets(3));
    expect(find.text('Snack'), findsOneWidget);
  });

  testWidgets('en ingles muestra los textos y los miles con coma', (
    tester,
  ) async {
    await _pump(tester, dailyLimit: 3000, locale: const Locale('en'));

    expect(find.text("Today's meals"), findsOneWidget);
    expect(find.text('View history'), findsOneWidget);
    expect(find.text("Today's calories"), findsOneWidget);
    expect(find.text('Goal: 3,000 kcal'), findsOneWidget);
    expect(find.text('consumed'), findsOneWidget);
    expect(
      find.text("You have 2,856 kcal left to reach today's goal."),
      findsOneWidget,
    );
  });

  testWidgets('recarga cuando se registra algo en otra pantalla', (
    tester,
  ) async {
    final repo = await _pump(tester);
    MealLogState.instance.bump();
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
  });

  testWidgets('muestra consumos manuales y comunes al registrarlos', (
    tester,
  ) async {
    final repo = _RepoFalso();
    final foods = FoodsViewModel(mealRepository: repo);
    await tester.pumpWidget(
      l10nApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                TodayMealsSection(
                  repository: repo,
                  progressRepository: _ProgressRepoFalso(2000),
                  clock: () => DateTime(2026, 10, 12, 21),
                ),
                ElevatedButton(
                  onPressed: () => foods.consumeFood(
                    foodId: 20,
                    quantity: 1,
                    mealType: MealType.breakfast,
                  ),
                  child: const Text('Registrar manualmente'),
                ),
                ElevatedButton(
                  onPressed: () => foods.consumeBatch([
                    (
                      food: FoodModel(
                        foodId: 21,
                        name: 'Arroz',
                        caloriesPerUnit: 100,
                        baseUnit: '100 G',
                        isGlobal: true,
                        isActive: true,
                      ),
                      quantity: 1,
                    ),
                    (
                      food: FoodModel(
                        foodId: 22,
                        name: 'Pollo',
                        caloriesPerUnit: 100,
                        baseUnit: '100 G',
                        isGlobal: true,
                        isActive: true,
                      ),
                      quantity: 1,
                    ),
                  ], MealType.dinner),
                  child: const Text('Registrar comunes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no registrada'), findsNWidgets(3));
    expect(
      find.text('Te faltan 1.856 kcal para cumplir tu objetivo de hoy.'),
      findsOneWidget,
    );

    final registerManual = find.text('Registrar manualmente');
    await tester.ensureVisible(registerManual);
    await tester.tap(registerManual);
    await tester.pumpAndSettle();
    expect(find.text('Avena • 100 kcal'), findsOneWidget);
    expect(find.text('244 kcal'), findsOneWidget);

    final registerCommon = find.text('Registrar comunes');
    await tester.ensureVisible(registerCommon);
    await tester.tap(registerCommon);
    await tester.pumpAndSettle();
    expect(find.text('Arroz, Pollo • 200 kcal'), findsOneWidget);
    expect(find.text('444 kcal'), findsOneWidget);
    expect(repo.loads, 3);
    foods.dispose();
  });

  testWidgets('muestra calorías excedidas por encima del objetivo diario', (
    tester,
  ) async {
    await _pump(tester, dailyLimit: 2000, initialCalories: 2345);

    expect(
      find.text('Te excediste por 345 kcal de tu objetivo diario.'),
      findsOneWidget,
    );
    expect(find.text('Objetivo: 2.000 kcal'), findsOneWidget);
  });

  testWidgets('tocar una comida muestra el detalle y permite borrar', (
    tester,
  ) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();
    expect(find.text('1½ porciones · 150 g'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar Tilapia'));
    await tester.pumpAndSettle();
    expect(repo.deleted.single, 5);
  });
}
