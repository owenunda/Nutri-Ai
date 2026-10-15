import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nutrilife/features/auth/presentation/screens/reset_password_screen.dart';

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

const _ok = (200, {'success': true, 'data': null});

/// Deja avanzar la petición de Dio sin consumir la cuenta regresiva de reenviar.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Abre [screen] encima de una pantalla "login" que muestra lo que le devuelven.
Future<void> _openOverLogin(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: _LoginStub(screen: screen),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await _settle(tester);
}

class _LoginStub extends StatefulWidget {
  const _LoginStub({required this.screen});

  final Widget screen;

  @override
  State<_LoginStub> createState() => _LoginStubState();
}

class _LoginStubState extends State<_LoginStub> {
  Object? _result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<Object?>(
              MaterialPageRoute(builder: (_) => widget.screen),
            );
            setState(() => _result = result);
          },
          child: const Text('abrir'),
        ),
        Text('resultado: $_result'),
      ],
    );
  }
}

AuthRepository _repo(_FakeAdapter adapter) => AuthRepository(
  dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter,
);

void main() {
  testWidgets('olvidé mi contraseña envía el código y abre la siguiente pantalla', (
    tester,
  ) async {
    final adapter = _FakeAdapter({ApiRoutes.authPasswordForgot: _ok});
    await _openOverLogin(
      tester,
      ForgotPasswordScreen(repository: _repo(adapter)),
    );

    await tester.enterText(find.byType(TextFormField), 'ana@gmail.com');
    await tester.tap(find.text('Enviar código'));
    await _settle(tester);

    expect(adapter.requests.single.data, {'email': 'ana@gmail.com'});
    expect(find.text('Nueva contraseña'), findsOneWidget);
  });

  testWidgets('olvidé mi contraseña valida el correo', (tester) async {
    final adapter = _FakeAdapter({ApiRoutes.authPasswordForgot: _ok});
    await _openOverLogin(
      tester,
      ForgotPasswordScreen(repository: _repo(adapter)),
    );

    await tester.enterText(find.byType(TextFormField), 'no-es-correo');
    await tester.tap(find.text('Enviar código'));
    await _settle(tester);

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('nueva contraseña: guardar vuelve al login con el correo', (
    tester,
  ) async {
    final adapter = _FakeAdapter({ApiRoutes.authPasswordReset: _ok});
    await _openOverLogin(
      tester,
      ResetPasswordScreen(email: 'ana@gmail.com', repository: _repo(adapter)),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '482913');
    await tester.enterText(fields.at(1), 'nueva123');
    await tester.enterText(fields.at(2), 'nueva123');
    await tester.tap(find.text('Guardar contraseña'));
    await _settle(tester);

    expect(adapter.requests.single.data, {
      'email': 'ana@gmail.com',
      'code': '482913',
      'password': 'nueva123',
    });
    expect(find.text('resultado: ana@gmail.com'), findsOneWidget);
  });

  testWidgets('nueva contraseña: código vencido muestra el error y no vuelve', (
    tester,
  ) async {
    final adapter = _FakeAdapter({
      ApiRoutes.authPasswordReset: (
        400,
        {
          'success': false,
          'message': 'El código venció. Pide uno nuevo.',
          'error': {'code': 'CODE_EXPIRED', 'details': <Object>[]},
        },
      ),
    });
    await _openOverLogin(
      tester,
      ResetPasswordScreen(email: 'ana@gmail.com', repository: _repo(adapter)),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '482913');
    await tester.enterText(fields.at(1), 'nueva123');
    await tester.enterText(fields.at(2), 'nueva123');
    await tester.tap(find.text('Guardar contraseña'));
    await _settle(tester);

    expect(find.text('El código venció. Pide uno nuevo.'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
  });
}
