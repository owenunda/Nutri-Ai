import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import '../../helpers/l10n_app.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/verify_email_screen.dart';

/// Responde según la ruta y guarda las peticiones.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final Map<String, (int, Object)> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = responses[options.path]!;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _session = {
  'success': true,
  'data': {
    'token': 'jwt-789',
    'user': {'userId': 11, 'name': 'Ana'},
    'needsProfileSetup': true,
  },
};

/// Deja avanzar la petición de Dio sin esperar a que termine la cuenta
/// regresiva del botón de reenviar (pumpAndSettle la consumiría entera).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<List<GoogleLoginResult>> _open(
  WidgetTester tester,
  _FakeAdapter adapter,
) async {
  // Pantalla de teléfono: con 800x600 los botones quedan fuera de la vista.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);

  final verified = <GoogleLoginResult>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    l10nApp(
      VerifyEmailScreen(
        email: 'ana@gmail.com',
        repository: AuthRepository(dio: dio),
        onVerified: (_, result) => verified.add(result),
      ),
    ),
  );
  return verified;
}

void main() {
  testWidgets('muestra el correo y verifica con el código', (tester) async {
    final adapter = _FakeAdapter({ApiRoutes.authVerifyEmail: (200, _session)});
    final verified = await _open(tester, adapter);

    expect(find.textContaining('ana@gmail.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '482913');
    await tester.tap(find.text('Verificar'));
    await _settle(tester);

    expect(adapter.requests.single.data, {'email': 'ana@gmail.com', 'code': '482913'});
    expect(verified.single.token, 'jwt-789');
  });

  testWidgets('un código incompleto no se envía', (tester) async {
    final adapter = _FakeAdapter({ApiRoutes.authVerifyEmail: (200, _session)});
    await _open(tester, adapter);

    await tester.enterText(find.byType(TextFormField), '4829');
    await tester.tap(find.text('Verificar'));
    await tester.pump();

    expect(find.text('Escribe los 6 dígitos del código.'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('código incorrecto muestra el error', (tester) async {
    final adapter = _FakeAdapter({
      ApiRoutes.authVerifyEmail: (
        400,
        {
          'success': false,
          'message': 'El código no es correcto.',
          'error': {'code': 'INVALID_CODE', 'details': <Object>[]},
        },
      ),
    });
    final verified = await _open(tester, adapter);

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verificar'));
    await _settle(tester);

    expect(find.text('El código no es correcto.'), findsOneWidget);
    expect(verified, isEmpty);
  });

  testWidgets('reenviar espera 60 segundos y después pide otro código', (tester) async {
    final adapter = _FakeAdapter({
      ApiRoutes.authVerifyEmailResend: (200, {'success': true, 'data': null}),
    });
    await _open(tester, adapter);

    expect(find.text('Reenviar código en 60 s'), findsOneWidget);
    await tester.tap(find.text('Reenviar código en 60 s'));
    await tester.pump();
    expect(adapter.requests, isEmpty);

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text('Reenviar código'));
    await _settle(tester);

    expect(adapter.requests.single.path, ApiRoutes.authVerifyEmailResend);
    expect(find.text('Te enviamos un código nuevo.'), findsOneWidget);
    expect(find.text('Reenviar código en 60 s'), findsOneWidget);
  });
}
