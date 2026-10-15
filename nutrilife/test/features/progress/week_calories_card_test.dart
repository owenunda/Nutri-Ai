import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/week_stats.dart';
import 'package:nutrilife/features/progress/presentation/widgets/week_calories_card.dart';

import '../../helpers/l10n_app.dart';

WeekStats _week({int? limit = 2000}) => WeekStats.fromJson({
      'dailyLimit': limit,
      'average': 1850,
      'daysOnTarget': 4,
      'days': [
        // 2026-10-06 es martes.
        for (var i = 6; i <= 12; i++) {'date': '2026-10-${i.toString().padLeft(2, '0')}', 'totalConsumed': 1500 + i * 50},
      ],
    });

Future<void> _pump(WidgetTester tester, WeekStats week, {Locale locale = const Locale('es')}) =>
    tester.pumpWidget(l10nApp(
      locale: locale,
      Scaffold(body: WeekCaloriesCard(week: week, clock: () => DateTime(2026, 10, 12, 9))),
    ));

void main() {
  testWidgets('iniciales de los días reales y resumen', (tester) async {
    await _pump(tester, _week());

    // Mar Mié Jue Vie Sáb Dom Lun
    for (final initial in ['M', 'J', 'V', 'S', 'D', 'L']) {
      expect(find.text(initial), findsWidgets);
    }
    expect(find.text('Promedio: 1.850 kcal/día · 4 de 7 días en tu meta'), findsOneWidget);
  });

  testWidgets('tocar una barra muestra ese día', (tester) async {
    await _pump(tester, _week());
    await tester.tap(find.byKey(const ValueKey('week-bar-2026-10-08')));
    await tester.pump();
    expect(find.text('Jue 8 · 1.900 kcal'), findsOneWidget);
  });

  testWidgets('sin meta muestra solo el promedio y el enlace', (tester) async {
    await _pump(tester, _week(limit: null));
    expect(find.text('Promedio: 1.850 kcal/día'), findsOneWidget);
    expect(find.text('Completa tu perfil'), findsOneWidget);
  });

  testWidgets('en inglés: iniciales, miles con coma y textos en inglés', (tester) async {
    await _pump(tester, _week(), locale: const Locale('en'));

    // Tue Wed Thu Fri Sat Sun Mon
    for (final initial in ['M', 'T', 'W', 'F', 'S']) {
      expect(find.text(initial), findsWidgets);
    }
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Average: 1,850 kcal/day · 4 of 7 days on target'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('week-bar-2026-10-08')));
    await tester.pump();
    expect(find.text('Thu 8 · 1,900 kcal'), findsOneWidget);
  });

  testWidgets('en inglés sin meta pide completar el perfil', (tester) async {
    await _pump(tester, _week(limit: null), locale: const Locale('en'));
    expect(find.text('Average: 1,850 kcal/day'), findsOneWidget);
    expect(find.text('Complete your profile'), findsOneWidget);
  });
}
