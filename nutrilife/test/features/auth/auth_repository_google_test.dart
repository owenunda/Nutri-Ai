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

  test('cuenta existente con contraseña: lanza GoogleLinkRequiredException', () async {
    final adapter = _FakeAdapter(409, {
      'success': false,
      'message':
          'Ya tienes una cuenta con este correo. Escribe tu contraseña para vincularla con Google.',
      'error': {'code': 'GOOGLE_LINK_REQUIRES_PASSWORD', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).loginWithGoogle('google-token'),
      throwsA(isA<GoogleLinkRequiredException>()),
    );
  });

  test('linkGoogle manda idToken y contraseña y lee la sesión', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'data': {
        'token': 'jwt-456',
        'user': {'userId': 7, 'name': 'Ana'},
        'needsProfileSetup': false,
        'offerPasswordSetup': false,
      },
    });

    final result = await _repoWith(adapter).linkGoogle('google-token', 'secreto123');

    expect(adapter.lastRequest!.path, ApiRoutes.authGoogleLink);
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.data, {
      'idToken': 'google-token',
      'password': 'secreto123',
    });
    expect(result.token, 'jwt-456');
    expect(result.user['userId'], 7);
  });

  test('linkGoogle con contraseña incorrecta lanza AuthException', () async {
    final adapter = _FakeAdapter(401, {
      'success': false,
      'message': 'Contraseña incorrecta',
      'error': {'code': 'INVALID_PASSWORD', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).linkGoogle('google-token', 'otra'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'La contraseña no es correcta.',
        ),
      ),
    );
  });

  test('verifyEmail manda correo y código y devuelve la sesión', () async {
    final adapter = _FakeAdapter(200, {
      'success': true,
      'data': {
        'token': 'jwt-789',
        'user': {'userId': 11, 'name': 'Ana'},
        'needsProfileSetup': true,
      },
    });

    final result = await _repoWith(adapter).verifyEmail('ana@gmail.com', '482913');

    expect(adapter.lastRequest!.path, ApiRoutes.authVerifyEmail);
    expect(adapter.lastRequest!.data, {'email': 'ana@gmail.com', 'code': '482913'});
    expect(result.token, 'jwt-789');
    expect(result.needsProfileSetup, isTrue);
  });

  test('verifyEmail con código equivocado lanza el mensaje del backend', () async {
    final adapter = _FakeAdapter(400, {
      'success': false,
      'message': 'El código no es correcto.',
      'error': {'code': 'INVALID_CODE', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).verifyEmail('ana@gmail.com', '000000'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'El código no es correcto.',
        ),
      ),
    );
  });

  test('resendVerification, forgotPassword y resetPassword llaman a su ruta', () async {
    final adapter = _FakeAdapter(200, {'success': true, 'data': null});
    final repo = _repoWith(adapter);

    await repo.resendVerification('ana@gmail.com');
    expect(adapter.lastRequest!.path, ApiRoutes.authVerifyEmailResend);
    expect(adapter.lastRequest!.data, {'email': 'ana@gmail.com'});

    await repo.forgotPassword('ana@gmail.com');
    expect(adapter.lastRequest!.path, ApiRoutes.authPasswordForgot);
    expect(adapter.lastRequest!.data, {'email': 'ana@gmail.com'});

    await repo.resetPassword('ana@gmail.com', '482913', 'nueva123');
    expect(adapter.lastRequest!.path, ApiRoutes.authPasswordReset);
    expect(adapter.lastRequest!.data, {
      'email': 'ana@gmail.com',
      'code': '482913',
      'password': 'nueva123',
    });
  });

  test('pedir un código antes de tiempo muestra la espera del backend', () async {
    final adapter = _FakeAdapter(429, {
      'success': false,
      'message': 'Espera 42 segundos para pedir otro código.',
      'error': {'code': 'CODE_RECENTLY_SENT', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).forgotPassword('ana@gmail.com'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Espera 42 segundos para pedir otro código.',
        ),
      ),
    );
  });
}
