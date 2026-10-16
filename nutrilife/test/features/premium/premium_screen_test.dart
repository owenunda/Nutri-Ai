import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('el anual viene elegido y se puede cambiar', (tester) async {
    await tester.pumpWidget(l10nApp(const PremiumScreen()));

    expect(find.text('Ahorra 50%'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-yearly-selected')), findsOneWidget);

    await tester.tap(find.text('Mensual'));
    await tester.pump();
    expect(find.byKey(const ValueKey('plan-monthly-selected')), findsOneWidget);
  });

  testWidgets('pagar todavía no cobra', (tester) async {
    // Pantalla de celular alto: el botón queda abajo y el ListView no lo
    // construye en la ventana de prueba por defecto.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(l10nApp(const PremiumScreen()));

    await tester.tap(find.text('Empezar 7 días gratis'));
    await tester.pump();
    expect(find.text('Los pagos llegan pronto'), findsOneWidget);
  });
}
