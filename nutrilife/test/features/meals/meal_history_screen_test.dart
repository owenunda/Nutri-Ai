import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/presentation/screens/meal_history_screen.dart';

class _RepoFalso extends MealRepository {
  final dates = <String>[];

  @override
  Future<DayMeals> getDay(String date) async {
    dates.add(date);
    return DayMeals.empty(date);
  }
}

void main() {
  testWidgets('navega por días y no pasa de hoy', (tester) async {
    final repo = _RepoFalso();
    await tester.pumpWidget(MaterialApp(
      home: MealHistoryScreen(repository: repo, clock: () => DateTime(2026, 10, 12, 9)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(repo.dates.last, '2026-10-12');
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Ayer'), findsOneWidget);
    expect(repo.dates.last, '2026-10-11');

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sáb 10 oct'), findsOneWidget);

    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pumpAndSettle();
    expect(repo.dates.last, '2026-10-11');
  });
}
