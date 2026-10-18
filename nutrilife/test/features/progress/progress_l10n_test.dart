import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';
import 'package:nutrilife/features/progress/presentation/screens/progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

class _RepoFalso extends ProgressRepository {
  _RepoFalso(this.data) : super(dio: Dio());

  final ProgressData data;

  @override
  Future<ProgressData> fetchProgress({DateTime? now}) async => data;
}

ProgressData _data({
  String? goal = 'Perder peso',
  String? status = 'EXCEDIDO',
  String? name = 'Ana',
}) {
  return ProgressData(
    profile: {'name': ?name, 'goal': goal, 'weight': 72.5, 'height': 170},
    history: [
      PhysicalRecord(weight: 72.5, height: 170, recordDate: DateTime(2026, 10, 12)),
      PhysicalRecord(weight: 74.0, height: 170, recordDate: DateTime(2026, 10, 5)),
    ],
    consumptionValidation: {
      'dailyLimit': 2000,
      'totalConsumed': 2450,
      'status': ?status,
    },
    todayCalories: null,
  );
}

Future<void> _pump(WidgetTester tester, ProgressData data, Locale locale) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(l10nApp(Scaffold(body: ProgressScreen(repository: _RepoFalso(data))), locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleState.instance.setPreference(LanguagePreference.system));

  group('ProgressData (modelo)', () {
    test('en español muestra lo de siempre', () async {
      await LocaleState.instance.setPreference(LanguagePreference.es);
      final data = _data();
      expect(data.goal, 'Perder peso');
      expect(data.goalLabel, 'Bajar peso');
      expect(data.statusLabel, 'EXCEDIDO');
      expect(data.isExceeded, isTrue);
      expect(_data(goal: null, status: null, name: null).goalLabel, 'Sin meta');
      expect(_data(goal: null, status: null, name: null).statusLabel, 'Sin datos');
      expect(_data(name: null).firstName, 'Usuario');
    });

    test('en inglés traduce lo que se muestra y no el valor del backend', () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      final data = _data();
      // El valor del backend sigue intacto; solo cambia la etiqueta.
      expect(data.goal, 'Perder peso');
      expect(data.goalLabel, 'Lose weight');
      expect(data.statusLabel, 'EXCEEDED');
      expect(data.isExceeded, isTrue);
      expect(_data(goal: 'Ganar peso').goalLabel, 'Gain weight');
      expect(_data(goal: 'Mantener peso').goalLabel, 'Maintain weight');
      expect(_data(status: 'OK').statusLabel, 'OK');
      expect(_data(status: 'OK').isExceeded, isFalse);
      expect(_data(goal: null, status: null, name: null).goalLabel, 'No goal');
      expect(_data(goal: null, status: null, name: null).statusLabel, 'No data');
      expect(_data(name: null).firstName, 'User');
    });

    test('la meta diaria calculada no depende del idioma', () async {
      final profile = {'age': 30, 'weight': 70, 'height': 170, 'goal': 'Perder peso'};
      ProgressData build() => ProgressData(
            profile: profile,
            history: const [],
            consumptionValidation: null,
            todayCalories: null,
          );
      await LocaleState.instance.setPreference(LanguagePreference.es);
      final es = build().dailyLimit;
      await LocaleState.instance.setPreference(LanguagePreference.en);
      expect(build().dailyLimit, es);
    });
  });

  testWidgets('ProgressScreen en español', (tester) async {
    await LocaleState.instance.setPreference(LanguagePreference.es);
    await _pump(tester, _data(), const Locale('es'));

    expect(find.text('PROGRESO SEMANAL'), findsOneWidget);
    expect(find.text('¡Buen progreso,\nAna!'), findsOneWidget);
    expect(find.text('Meta:\nBajar peso'), findsOneWidget);
    expect(find.text('Calorías de hoy'), findsOneWidget);
    expect(find.text('2.450'), findsOneWidget);
    expect(find.text('de 2.000 kcal'), findsOneWidget);
    expect(find.text('EXCEDIDO'), findsWidgets);
    expect(find.textContaining('desde el registro anterior', findRichText: true), findsOneWidget);
    expect(find.text('Historial de peso'), findsOneWidget);
    expect(find.text('OCT 5'), findsOneWidget);
    expect(find.text('OCT 12'), findsOneWidget);
    expect(find.text('72.5kg Actual'), findsOneWidget);
  });

  testWidgets('ProgressScreen en inglés', (tester) async {
    await LocaleState.instance.setPreference(LanguagePreference.en);
    await _pump(tester, _data(), const Locale('en'));

    expect(find.text('WEEKLY PROGRESS'), findsOneWidget);
    expect(find.text('Great progress,\nAna!'), findsOneWidget);
    expect(find.text('Goal:\nLose weight'), findsOneWidget);
    expect(find.text("Today's calories"), findsOneWidget);
    expect(find.text('2,450'), findsOneWidget);
    expect(find.text('of 2,000 kcal'), findsOneWidget);
    expect(find.text('EXCEEDED'), findsWidgets);
    expect(find.textContaining('since your last entry', findRichText: true), findsOneWidget);
    expect(find.text('Weight history'), findsOneWidget);
    expect(find.text('Log weight'), findsOneWidget);
    expect(find.text('OCT 5'), findsOneWidget);
    expect(find.text('Current: 72.5 kg'), findsOneWidget);
    expect(find.text('Daily goal: 2,000 kcal. You have 0 kcal left today.'), findsOneWidget);
  });
}
