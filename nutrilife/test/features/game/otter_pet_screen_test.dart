import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/game/domain/habitat_scene.dart';
import 'package:nutrilife/features/game/domain/otter_skin.dart';
import 'package:nutrilife/features/game/presentation/screens/otter_pet_screen.dart';
import 'package:nutrilife/features/game/presentation/widgets/otter_sprite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder spriteOf(OtterSkin skin) => find.byWidgetPredicate(
    (w) => w is OtterSprite && w.sheet == skin.idleSheet && w.size > 200,
  );

  Finder backgroundOf(String asset) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == asset,
  );

  // Abre una hoja y espera su animación (pumpAndSettle no sirve: el Ticker
  // del juego nunca se detiene).
  Future<void> tapAndSettleSheet(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Deja la escena de noche sin depender de la hora en que corre el test.
  Future<void> goToNight(WidgetTester tester) async {
    if (find.byTooltip('Ver de noche').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Ver de noche'));
      await tester.pump();
    }
  }

  Future<void> stroke(WidgetTester tester, {required int passes}) async {
    final center = tester.getCenter(find.byType(OtterSprite));
    final gesture = await tester.startGesture(center - const Offset(60, 0));
    for (var i = 0; i < passes; i++) {
      for (var s = 0; s < 6; s++) {
        await gesture.moveBy(Offset(i.isEven ? 20 : -20, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await gesture.up();
    await tester.pump();
  }

  testWidgets('acariciar con el dedo hace feliz a la nutria', (tester) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    await tester.pump(); // lee la nutria guardada
    expect(find.text('Acaricia a la nutria con el dedo'), findsOneWidget);

    await stroke(tester, passes: 2);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    expect(find.text('¡Le encantó! 💚'), findsNothing);

    await stroke(tester, passes: 6);
    expect(find.text('¡Le encantó! 💚'), findsOneWidget);
  });

  testWidgets('un toque sin mover el dedo no cuenta', (tester) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(OtterSprite));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.text('¡Le encantó! 💚'), findsNothing);
  });

  testWidgets('cambiar a la nutria chef la muestra y la recuerda', (
    tester,
  ) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    await tester.pump();
    expect(spriteOf(OtterSkin.normal), findsOneWidget);

    await tester.tap(find.byTooltip('Cambiar de nutria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tu colección'), findsOneWidget);
    await tester.tap(find.text('Chef'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(spriteOf(OtterSkin.chef), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('game_otter_skin'), 'chef');

    // Al volver a entrar sigue la chef, sin mostrar antes la clásica.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    expect(spriteOf(OtterSkin.normal), findsNothing);
    await tester.pump();
    expect(spriteOf(OtterSkin.chef), findsOneWidget);
  });

  testWidgets('cambiar de lugar lo muestra y lo recuerda', (tester) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    await tester.pump();
    await goToNight(tester);
    expect(backgroundOf(HabitatScene.habitacion.nightAsset), findsOneWidget);

    await tapAndSettleSheet(tester, find.byTooltip('Cambiar de lugar'));
    expect(find.text('Lugares'), findsOneWidget);
    await tapAndSettleSheet(tester, find.text('Costa'));

    expect(backgroundOf(HabitatScene.costa.nightAsset), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('game_habitat'), 'costa');

    // Fuera de la habitación no cuelga el foco.
    expect(find.bySemanticsLabel('Apagar la luz'), findsNothing);

    await tester.tap(find.byTooltip('Ver de día'));
    await tester.pump();
    expect(backgroundOf(HabitatScene.costa.dayAsset), findsOneWidget);
  });

  testWidgets('de noche, apagar el foco oscurece la habitación', (
    tester,
  ) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    await tester.pump();
    await goToNight(tester);
    Finder darkness() => find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == const Color(0x8C000000),
    );
    expect(darkness(), findsNothing);

    await tester.tap(find.bySemanticsLabel('Apagar la luz'));
    await tester.pump();
    expect(darkness(), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Prender la luz'));
    await tester.pump();
    expect(darkness(), findsNothing);
  });
}
