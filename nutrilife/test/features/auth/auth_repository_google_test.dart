import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';

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

AuthRepository _repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return AuthRepository(dio: dio);
}

void main() {
  test('manda el idToken y lee token, usuario y needsProfileSetup', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'message': 'Login successful',
      'data': {
        'token': 'jwt-123',
        'user': {'userId': 9, 'name': 'Ana'},
        'needsProfileSetup': true,
        'offerPasswordSetup': true,
      },
    });

    final result = await _repoWith(adapter).loginWithGoogle('google-token');

    expect(result.offerPasswordSetup, isTrue);
    expect(adapter.lastRequest!.path, ApiRoutes.authGoogle);
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.data, {'idToken': 'google-token'});
    expect(result.token, 'jwt-123');
    expect(result.user['name'], 'Ana');
    expect(result.needsProfileSetup, isTrue);
  });

  test('sin needsProfileSetup ni offerPasswordSetup cuentan como false', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'data': {
        'token': 'jwt-123',
        'user': {'userId': 9},
      },
    });

    final result = await _repoWith(adapter).loginWithGoogle('google-token');

    expect(result.needsProfileSetup, isFalse);
    expect(result.offerPasswordSetup, isFalse);
  });

  test('setPassword manda la contraseña a /user/password', () async {
    final adapter = _FakeAdapter(200, {'success': true, 'data': null});

    await _repoWith(adapter).setPassword('nueva123');

    expect(adapter.lastRequest!.path, ApiRoutes.userPassword);
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.data, {'password': 'nueva123'});
  });

  test('setPassword: error del backend lanza AuthException con su mensaje', () async {
    final adapter = _FakeAdapter(409, {
      'success': false,
      'message': 'Tu cuenta ya tiene contraseña.',
      'error': {'code': 'PASSWORD_ALREADY_SET', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).setPassword('nueva123'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Tu cuenta ya tiene contraseña.',
        ),
      ),
    );
  });

  test('error del backend: lanza AuthException con su mensaje', () async {
    final adapter = _FakeAdapter(409, {
      'success': false,
      'message': 'Este correo ya está vinculado a otra cuenta de Google.',
      'error': {'code': 'GOOGLE_ACCOUNT_CONFLICT', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).loginWithGoogle('google-token'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Este correo ya está vinculado a otra cuenta de Google.',
        ),
      ),
    );
  });
}
