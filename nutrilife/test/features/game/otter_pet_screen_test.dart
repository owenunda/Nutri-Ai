import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/game/presentation/screens/otter_pet_screen.dart';

import '../../helpers/l10n_app.dart';

void main() {
  Future<void> stroke(WidgetTester tester, {required int passes}) async {
    final center = tester.getCenter(find.byType(Listener).last);
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
    expect(find.text('Acaricia a la nutria con el dedo'), findsOneWidget);

    await stroke(tester, passes: 2);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    expect(find.text('¡Le encantó! 💚'), findsNothing);

    await stroke(tester, passes: 6);
    expect(find.text('¡Le encantó! 💚'), findsOneWidget);
  });

  testWidgets('un toque sin mover el dedo no cuenta', (tester) async {
    await tester.pumpWidget(l10nApp(const OtterPetScreen()));
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(Listener).last);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.text('¡Le encantó! 💚'), findsNothing);
  });
}
