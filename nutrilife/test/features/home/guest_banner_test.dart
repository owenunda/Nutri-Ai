import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/home/presentation/widgets/guest_banner.dart';

import '../../helpers/l10n_app.dart';

final _now = DateTime(2026, 10, 18, 12);

Widget _banner({required Duration left, VoidCallback? onCreateAccount}) => l10nApp(
  Scaffold(
    body: GuestBanner(
      expiresAt: _now.add(left),
      now: () => _now,
      onCreateAccount: onCreateAccount ?? () {},
    ),
  ),
);

void main() {
  testWidgets('dice cuántas horas le quedan', (tester) async {
    await tester.pumpWidget(_banner(left: const Duration(hours: 23, minutes: 40)));

    expect(find.text('Modo invitado · se borra en 23 h'), findsOneWidget);
  });

  testWidgets('con menos de una hora lo dice', (tester) async {
    await tester.pumpWidget(_banner(left: const Duration(minutes: 20)));

    expect(find.text('Modo invitado · se borra en menos de 1 h'), findsOneWidget);
  });

  testWidgets('Crear cuenta llama al callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_banner(left: const Duration(hours: 5), onCreateAccount: () => taps++));

    await tester.tap(find.text('Crear cuenta'));
    expect(taps, 1);
  });

  testWidgets('en inglés cabe a 375 px', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(l10nApp(
      Scaffold(
        body: GuestBanner(expiresAt: _now.add(const Duration(hours: 23)), now: () => _now, onCreateAccount: () {}),
      ),
      locale: const Locale('en'),
    ));

    expect(find.text('Guest mode · deleted in 23 h'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
