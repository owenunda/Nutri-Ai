import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/home/presentation/widgets/today_meals_section.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';

class _RepoFalso extends MealRepository {
  int loads = 0;
  final deleted = <int>[];
  String? lastDate;

  @override
  Future<DayMeals> getDay(String date) async {
    loads++;
    lastDate = date;
    return DayMeals.fromJson({
      'date': date,
      'totalCalories': 144,
      'meals': {
        'LUNCH': {
          'totalCalories': 144,
          'items': [
            {'detailId': 5, 'foodId': 3, 'name': 'Tilapia', 'baseUnit': '100 G', 'quantity': 1.5, 'calories': 144}
          ]
        },
      },
    });
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

Future<_RepoFalso> _pump(WidgetTester tester) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TodayMealsSection(repository: repo, clock: () => DateTime(2026, 10, 12, 21)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('muestra lo registrado hoy y lo que falta', (tester) async {
    final repo = await _pump(tester);

    expect(repo.lastDate, '2026-10-12');
    expect(find.text('Tilapia • 144 kcal'), findsOneWidget);
    expect(find.text('Aún no registrada'), findsNWidgets(3));
    expect(find.text('Snack'), findsOneWidget);
  });

  testWidgets('recarga cuando se registra algo en otra pantalla', (tester) async {
    final repo = await _pump(tester);
    MealLogState.instance.bump();
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
  });

  testWidgets('tocar una comida muestra el detalle y permite borrar', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();
    expect(find.text('1½ porciones · 150 g'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar Tilapia'));
    await tester.pumpAndSettle();
    expect(repo.deleted.single, 5);
  });
}
