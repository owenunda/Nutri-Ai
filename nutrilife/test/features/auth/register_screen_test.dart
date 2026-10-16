import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/register_screen.dart';

import '../../helpers/l10n_app.dart';

/// Responde siempre lo mismo.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

Future<void> _open(WidgetTester tester, _FakeAdapter adapter) async {
  // Pantalla grande para que los botones queden a la vista.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // La fuente de test (Ahem) ocupa más que la real: se achica para que la fila
  // de "¿Ya tienes una cuenta?" no desborde.
  tester.platformDispatcher.textScaleFactorTestValue = 0.8;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    l10nApp(RegisterScreen(repository: AuthRepository(dio: dio))),
  );
}

Future<void> _fillAndSubmit(WidgetTester tester, {bool acceptTerms = true}) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
  await tester.enterText(find.byType(TextFormField).at(1), 'ana@gmail.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'secreto123');
  await tester.enterText(find.byType(TextFormField).at(3), 'secreto123');
  if (acceptTerms) {
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
  }
  await tester.tap(find.text('Registrarse'));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('correo duplicado muestra el aviso de correo ya registrado', (
    tester,
  ) async {
    await _open(
      tester,
      _FakeAdapter(409, {
        'success': false,
        'message': 'Ese correo ya está registrado.',
        'error': {'code': 'EMAIL_ALREADY_EXISTS', 'details': <Object>[]},
      }),
    );

    await _fillAndSubmit(tester);

    expect(find.text('Correo ya registrado'), findsOneWidget);
    expect(find.text('Ese correo ya está registrado.'), findsOneWidget);
    expect(find.text('Registro no completado'), findsNothing);
  });

  testWidgets('otro error del backend muestra registro no completado', (
    tester,
  ) async {
    await _open(
      tester,
      _FakeAdapter(500, {
        'success': false,
        'message': 'Algo salió mal.',
        'error': {'code': 'INTERNAL_ERROR', 'details': <Object>[]},
      }),
    );

    await _fillAndSubmit(tester);

    expect(find.text('Registro no completado'), findsOneWidget);
    expect(find.text('Algo salió mal.'), findsOneWidget);
  });

  testWidgets('sin aceptar los términos muestra el aviso de falta confirmar', (
    tester,
  ) async {
    await _open(tester, _FakeAdapter(200, {'success': true}));

    await _fillAndSubmit(tester, acceptTerms: false);

    expect(find.text('Falta confirmar'), findsOneWidget);
    expect(
      find.text(
        'Debes aceptar los términos del servicio y la política de privacidad.',
      ),
      findsOneWidget,
    );
  });
}
