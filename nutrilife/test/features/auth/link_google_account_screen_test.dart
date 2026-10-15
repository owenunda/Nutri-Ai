import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import '../../helpers/l10n_app.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/link_google_account_screen.dart';

/// Responde siempre lo mismo y guarda las peticiones.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

const _session = {
  'success': true,
  'data': {
    'token': 'jwt-456',
    'user': {'userId': 7, 'name': 'Ana'},
    'needsProfileSetup': false,
    'offerPasswordSetup': false,
  },
};

/// Abre la pantalla encima de una pantalla "anterior", como hace el flujo.
Future<List<GoogleLoginResult>> _open(
  WidgetTester tester,
  _FakeAdapter adapter,
) async {
  final linked = <GoogleLoginResult>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;

  await tester.pumpWidget(
    l10nApp(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LinkGoogleAccountScreen(
                  idToken: 'google-token',
                  repository: AuthRepository(dio: dio),
                  onLinked: (_, result) => linked.add(result),
                ),
              ),
            ),
            child: const Text('pantalla anterior'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('pantalla anterior'));
  await tester.pumpAndSettle();
  return linked;
}

void main() {
  testWidgets('con la contraseña correcta vincula', (tester) async {
    final adapter = _FakeAdapter(200, _session);
    final linked = await _open(tester, adapter);

    await tester.enterText(find.byType(TextFormField), 'secreto123');
    await tester.tap(find.text('Vincular'));
    await tester.pumpAndSettle();

    expect(adapter.requests.single.path, ApiRoutes.authGoogleLink);
    expect(adapter.requests.single.data, {
      'idToken': 'google-token',
      'password': 'secreto123',
    });
    expect(linked.single.token, 'jwt-456');
  });

  testWidgets('contraseña incorrecta muestra el error y no vincula', (tester) async {
    final adapter = _FakeAdapter(401, {
      'success': false,
      'message': 'La contraseña no es correcta.',
      'error': {'code': 'INVALID_PASSWORD', 'details': <Object>[]},
    });
    final linked = await _open(tester, adapter);

    await tester.enterText(find.byType(TextFormField), 'otra');
    await tester.tap(find.text('Vincular'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña no es correcta.'), findsOneWidget);
    expect(linked, isEmpty);
  });

  testWidgets('sin contraseña no envía nada', (tester) async {
    final adapter = _FakeAdapter(200, _session);
    await _open(tester, adapter);

    await tester.tap(find.text('Vincular'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('"Cancelar" vuelve a la pantalla anterior', (tester) async {
    final adapter = _FakeAdapter(200, _session);
    await _open(tester, adapter);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla anterior'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });
}
