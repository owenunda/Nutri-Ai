import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/set_password_screen.dart';

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

Widget _screenWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return MaterialApp(
    home: SetPasswordScreen(
      nextScreen: () => const Scaffold(body: Text('siguiente pantalla')),
      repository: AuthRepository(dio: dio),
    ),
  );
}

Finder _field(int index) => find.byType(TextFormField).at(index);

void main() {
  testWidgets('"Ahora no" sigue sin llamar al backend', (tester) async {
    final adapter = _FakeAdapter(200, {'success': true});
    await tester.pumpWidget(_screenWith(adapter));

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text('siguiente pantalla'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('contraseñas distintas no se envían', (tester) async {
    final adapter = _FakeAdapter(200, {'success': true});
    await tester.pumpWidget(_screenWith(adapter));

    await tester.enterText(_field(0), 'nueva123');
    await tester.enterText(_field(1), 'otra1234');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('guardar envía la contraseña y sigue', (tester) async {
    final adapter = _FakeAdapter(200, {'success': true, 'data': null});
    await tester.pumpWidget(_screenWith(adapter));

    await tester.enterText(_field(0), 'nueva123');
    await tester.enterText(_field(1), 'nueva123');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(adapter.requests.single.path, ApiRoutes.userPassword);
    expect(adapter.requests.single.data, {'password': 'nueva123'});
    expect(find.text('siguiente pantalla'), findsOneWidget);
  });

  testWidgets('un error del backend se muestra y no sigue', (tester) async {
    final adapter = _FakeAdapter(409, {
      'success': false,
      'message': 'Tu cuenta ya tiene contraseña.',
      'error': {'code': 'PASSWORD_ALREADY_SET', 'details': <Object>[]},
    });
    await tester.pumpWidget(_screenWith(adapter));

    await tester.enterText(_field(0), 'nueva123');
    await tester.enterText(_field(1), 'nueva123');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta ya tiene contraseña.'), findsOneWidget);
    expect(find.text('siguiente pantalla'), findsNothing);
  });
}
