import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/profile/presentation/widgets/language_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('elegir English cambia la preferencia y cierra el panel', (tester) async {
    final state = LocaleState(deviceLocale: () => const Locale('es'));
    await state.load();

    await tester.pumpWidget(l10nApp(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showLanguageSheet(context, state: state),
          child: const Text('abrir'),
        ),
      ),
    )));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Elige el idioma'), findsOneWidget);
    expect(find.text('Usar el del teléfono'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(state.preference, LanguagePreference.en);
    expect(find.text('Elige el idioma'), findsNothing);
  });

  testWidgets('marca con check la opción actual y permite volver a "Usar el del teléfono"',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    final state = LocaleState(deviceLocale: () => const Locale('es'));
    await state.load();
    expect(state.preference, LanguagePreference.en);

    await tester.pumpWidget(l10nApp(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showLanguageSheet(context, state: state),
          child: const Text('abrir'),
        ),
      ),
    )));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Solo la opción actual (English) muestra el check.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('English'), matching: find.byType(Container)).first,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Usar el del teléfono'));
    await tester.pumpAndSettle();

    expect(state.preference, LanguagePreference.system);
    expect(find.text('Elige el idioma'), findsNothing);
  });
}
