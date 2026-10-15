import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:nutrilife/features/hydration/presentation/screens/water_streak_screen.dart';
import 'package:nutrilife/features/hydration/presentation/widgets/hydration_stats_card.dart';
import 'package:nutrilife/features/hydration/presentation/widgets/water_drop_shortcut.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('registra un vaso y actualiza el avance de inmediato', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: WaterStreakScreen(accountId: 'user@example.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('0/4'), findsOneWidget);
    expect(
      find.text('¡Hola! ¿Me ayudas a llenar mi vasito hoy?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('add-water-glass')));
    await tester.pumpAndSettle();

    expect(find.text('1/4'), findsOneWidget);
    expect(
      find.text('Te faltan 3 vasos para completar el reto.'),
      findsOneWidget,
    );
    expect(find.text('¡Gracias! Cada vasito cuenta.'), findsOneWidget);
  });

  testWidgets('la gota se llena al registrar un vaso', (tester) async {
    final repository = WaterStreakRepository(accountId: 'user@example.com');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaterDropShortcut(
            accountId: 'user@example.com',
            onTap: () async {
              await repository.addGlass();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Racha de agua, 0 de 4 vasos hoy'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('water-drop-shortcut')));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Racha de agua, 1 de 4 vasos hoy'),
      findsOneWidget,
    );
  });

  testWidgets(
    'la gota abre el reto con historiales anteriores de cinco vasos',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'water_streak_v1_user%40example.com': '{"2026-10-14":5}',
      });
      var opened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaterDropShortcut(
              accountId: 'user@example.com',
              onTap: () async {
                opened = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('water-drop-shortcut')));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    },
  );

  testWidgets('muestra las rachas y las metas cumplidas de la semana', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = WaterStreakRepository(accountId: 'stats@example.com');
    for (final day in [DateTime(2026, 10, 12), DateTime(2026, 10, 13)]) {
      for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
        await repository.addGlass(now: day);
      }
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HydrationStatsCard(
              accountId: 'stats@example.com',
              title: 'Hidratación semanal',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hydration-stats-card')), findsOneWidget);
    expect(find.text('HIDRATACIÓN SEMANAL'), findsOneWidget);
    expect(find.text('2 metas cumplidas'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('celebra al alcanzar la meta de cuatro vasos', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: WaterStreakScreen(accountId: 'celebration@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    for (var glass = 0; glass < WaterStreakRepository.dailyGoal; glass++) {
      await tester.tap(find.byKey(const ValueKey('add-water-glass')));
      await tester.pumpAndSettle();
      if (glass < WaterStreakRepository.dailyGoal - 1) {
        expect(find.text('¡Meta de agua cumplida!'), findsNothing);
      }
    }

    expect(find.text('¡Meta de agua cumplida!'), findsOneWidget);
    expect(
      find.text(
        '¡La nutria está celebrando contigo! Cada día estás construyendo un gran hábito.',
      ),
      findsOneWidget,
    );
  });
}
