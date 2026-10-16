import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/home/presentation/widgets/water_streak_home_card.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:nutrilife/features/hydration/presentation/screens/water_streak_screen.dart';
import 'package:nutrilife/features/hydration/presentation/widgets/hydration_stats_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

const _en = Locale('en');

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la racha de agua en inglés: título, diálogo y plurales', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      l10nApp(const WaterStreakScreen(accountId: 'en@example.com'), locale: _en),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water streak'), findsOneWidget);
    expect(find.text("Today's challenge"), findsOneWidget);
    expect(
      find.text('Hi! Will you help me fill my little glass today?'),
      findsOneWidget,
    );
    expect(find.text('0 days'), findsOneWidget);

    for (var glass = 0; glass < 3; glass++) {
      await tester.tap(find.byKey(const ValueKey('add-water-glass')));
      await tester.pumpAndSettle();
    }

    expect(find.text('1 more glass to complete the challenge.'), findsOneWidget);
    expect(find.text('Undo last glass'), findsOneWidget);
  });

  testWidgets('en español el plural de un vaso queda en singular', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      l10nApp(const WaterStreakScreen(accountId: 'es@example.com')),
    );
    await tester.pumpAndSettle();

    for (var glass = 0; glass < 3; glass++) {
      await tester.tap(find.byKey(const ValueKey('add-water-glass')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Te falta 1 vaso para completar el reto.'), findsOneWidget);
  });

  testWidgets('la meta cumplida celebra en inglés', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      l10nApp(const WaterStreakScreen(accountId: 'goal@example.com'), locale: _en),
    );
    await tester.pumpAndSettle();

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
      await tester.tap(find.byKey(const ValueKey('add-water-glass')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Water goal reached!'), findsOneWidget);
    expect(find.text('Awesome!'), findsOneWidget);
    expect(find.text('Challenge complete'), findsOneWidget);
  });

  testWidgets('la tarjeta de Inicio en inglés', (tester) async {
    await tester.pumpWidget(
      l10nApp(
        Scaffold(
          body: WaterStreakHomeCard(accountId: 'home@example.com', onTap: () async {}),
        ),
        locale: _en,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HYDRATION'), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('0/4 glasses today · 0-day streak'), findsOneWidget);
    expect(find.text('A small habit, a big step'), findsOneWidget);
  });

  testWidgets('las estadísticas en inglés usan iniciales en inglés', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      l10nApp(
        const Scaffold(
          body: SingleChildScrollView(
            child: HydrationStatsCard(accountId: 'stats-en@example.com'),
          ),
        ),
        locale: _en,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YOUR HYDRATION'), findsOneWidget);
    expect(find.text('Every glass counts'), findsOneWidget);
    expect(find.text('0 goals met'), findsOneWidget);
    expect(find.text('Daily goal: 4 glasses · Personal log, not medical advice.'), findsOneWidget);
    // Miércoles es "W" en inglés; en español la tarjeta usa "X".
    expect(find.text('X'), findsNothing);
    expect(find.text('W'), findsOneWidget);
  });
}
