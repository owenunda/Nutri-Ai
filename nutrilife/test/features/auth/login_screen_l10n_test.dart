import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/auth/presentation/screens/login_screen.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('el login se ve en inglés con el idioma en', (tester) async {
    await tester.pumpWidget(
      l10nApp(const LoginScreen(), locale: const Locale('en')),
    );
    await tester.pump();

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Entra a tu cuenta'), findsNothing);
  });

  testWidgets('el login se ve en español con el idioma es', (tester) async {
    await tester.pumpWidget(l10nApp(const LoginScreen()));
    await tester.pump();

    expect(find.text('Entra a tu cuenta'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsNothing);
  });
}
