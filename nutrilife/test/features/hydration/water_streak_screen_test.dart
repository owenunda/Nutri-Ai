import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/hydration/data/water_streak_repository.dart';
import 'package:nutrilife/features/hydration/presentation/screens/water_streak_screen.dart';
import 'package:nutrilife/features/hydration/presentation/widgets/hydration_stats_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

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
      l10nApp(const WaterStreakScreen(accountId: 'user@example.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('0/4'), findsOneWidget);
    expect(
      find.text('¡Hola! ¿Me ayudas a llenar mi vasito hoy?'),
      findsOneWidget,
    );
    // Cada nivel trae su propia nutria: no se le suma otra encima.
    expect(
      find.byKey(
        const ValueKey('assets/images/hydration/hidratacion_01_vacio.png'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('nutria'),
      ),
      findsNothing,
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
      l10nApp(
        const Scaffold(
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
      l10nApp(
        const WaterStreakScreen(accountId: 'celebration@example.com'),
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
