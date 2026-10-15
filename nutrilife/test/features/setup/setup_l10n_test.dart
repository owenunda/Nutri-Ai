import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/setup/data/setup_repository.dart';
import 'package:nutrilife/features/setup/presentation/screens/goal_setup_screen.dart';
import 'package:nutrilife/features/setup/presentation/screens/profile_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

/// Responde siempre lo mismo y guarda la última petición.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SetupRepository _repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return SetupRepository(dio: dio);
}

/// Pantalla alta para que el formulario entero quepa sin scroll.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('GoalSetupScreen', () {
    testWidgets('se ve en español', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(l10nApp(const GoalSetupScreen()));
      await tester.pump();

      expect(find.text('Define tu objetivo'), findsOneWidget);
      expect(find.text('Bajar de peso'), findsOneWidget);
      expect(find.text('Mantener peso'), findsOneWidget);
      expect(find.text('Subir de peso'), findsOneWidget);
      expect(find.text('Empieza tu meta'), findsOneWidget);
    });

    testWidgets('se ve en inglés', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(
        l10nApp(const GoalSetupScreen(), locale: const Locale('en')),
      );
      await tester.pump();

      expect(find.text('Set your goal'), findsOneWidget);
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('Maintain weight'), findsOneWidget);
      expect(find.text('Gain weight'), findsOneWidget);
      expect(find.text('Start your goal'), findsOneWidget);
      expect(find.text('Define tu objetivo'), findsNothing);
    });

    for (final (label, backendGoal) in [
      ('Lose weight', 'Perder peso'),
      ('Maintain weight', 'Mantener peso'),
      ('Gain weight', 'Ganar peso'),
    ]) {
      testWidgets('en inglés "$label" manda "$backendGoal" al backend', (
        tester,
      ) async {
        _tallScreen(tester);
        final adapter = _FakeAdapter(400, {
          'success': false,
          'message': 'Validation error',
        });
        await tester.pumpWidget(
          l10nApp(
            GoalSetupScreen(repository: _repoWith(adapter)),
            locale: const Locale('en'),
          ),
        );
        await tester.pump();

        await tester.tap(find.text(label));
        await tester.pump();
        await tester.tap(find.text('Start your goal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(adapter.lastRequest!.data, {'goal': backendGoal});
        // El mensaje del backend se muestra tal cual, sin mapa local.
        expect(find.text('Validation error'), findsOneWidget);
        expect(find.text("Couldn't save"), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  });

  group('ProfileSetupScreen', () {
    testWidgets('se ve en inglés', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(
        l10nApp(const ProfileSetupScreen(), locale: const Locale('en')),
      );
      await tester.pump();

      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('AGE'), findsOneWidget);
      expect(find.text('WEIGHT (KG)'), findsOneWidget);
      expect(find.text('HEIGHT (CM)'), findsOneWidget);
      expect(find.text('SEX'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Save profile'), findsOneWidget);
      expect(find.text('Completa tu perfil'), findsNothing);
    });

    testWidgets('se ve en español', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(l10nApp(const ProfileSetupScreen()));
      await tester.pump();

      expect(find.text('Completa tu perfil'), findsOneWidget);
      expect(find.text('Hombre'), findsOneWidget);
      expect(find.text('Mujer'), findsOneWidget);
      expect(find.text('Guardar perfil'), findsOneWidget);
    });

    testWidgets('sin sexo elegido avisa con el título de advertencia', (
      tester,
    ) async {
      _tallScreen(tester);
      await tester.pumpWidget(
        l10nApp(const ProfileSetupScreen(), locale: const Locale('en')),
      );
      await tester.pump();

      await tester.tap(find.text('Save profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Select your sex to continue.'), findsOneWidget);
      expect(find.text('Missing info'), findsOneWidget);
      expect(find.text("Couldn't save"), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('en español la advertencia sigue siendo una advertencia', (
      tester,
    ) async {
      _tallScreen(tester);
      await tester.pumpWidget(l10nApp(const ProfileSetupScreen()));
      await tester.pump();

      await tester.tap(find.text('Guardar perfil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Selecciona tu sexo para continuar.'), findsOneWidget);
      expect(find.text('Falta un dato'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('SetupRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await LocaleState.instance.setPreference(LanguagePreference.system);
    });

    test('muestra el mensaje del backend sin traducirlo', () async {
      final adapter = _FakeAdapter(400, {
        'success': false,
        'message': 'Validation error',
        'error': {
          'code': 'VALIDATION_ERROR',
          'details': [
            {'message': 'Age must be between 16 and 120'},
          ],
        },
      });

      expect(
        () => _repoWith(adapter).updateProfile(age: 10),
        throwsA(
          isA<SetupException>().having(
            (e) => e.message,
            'message',
            'Age must be between 16 and 120',
          ),
        ),
      );
    });

    test('sin datos: el aviso sale en el idioma de la app', () async {
      final adapter = _FakeAdapter(200, {'success': true});

      await LocaleState.instance.setPreference(LanguagePreference.en);
      await expectLater(
        () => _repoWith(adapter).updateProfile(),
        throwsA(
          isA<SetupException>().having(
            (e) => e.message,
            'message',
            "There's nothing to save.",
          ),
        ),
      );

      await LocaleState.instance.setPreference(LanguagePreference.es);
      await expectLater(
        () => _repoWith(adapter).updateProfile(),
        throwsA(
          isA<SetupException>().having(
            (e) => e.message,
            'message',
            'No hay datos para guardar.',
          ),
        ),
      );
    });

    test('respuesta sin mensaje usa el texto local del idioma', () async {
      final adapter = _FakeAdapter(500, {'success': false});

      await LocaleState.instance.setPreference(LanguagePreference.en);
      await expectLater(
        () => _repoWith(adapter).updateProfile(goal: 'Perder peso'),
        throwsA(
          isA<SetupException>().having(
            (e) => e.message,
            'message',
            "We couldn't save your info. Please try again.",
          ),
        ),
      );
    });
  });
}
