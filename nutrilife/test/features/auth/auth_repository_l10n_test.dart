import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El backend responde un 500 sin mensaje: la app usa su propio texto.
class _NoMessageAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': false}),
      500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthRepository _repo() => AuthRepository(
  dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _NoMessageAdapter(),
);

Future<String> _setPasswordError() async {
  try {
    await _repo().setPassword('secreto123');
  } on AuthException catch (error) {
    return error.message;
  }
  fail('setPassword debía fallar');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleState.instance.setPreference(LanguagePreference.system));

  test('sin mensaje del backend, el texto de respaldo sale en inglés', () async {
    await LocaleState.instance.setPreference(LanguagePreference.en);
    expect(
      await _setPasswordError(),
      "We couldn't save your password. Please try again.",
    );
  });

  test('y en español cuando la app está en español', () async {
    await LocaleState.instance.setPreference(LanguagePreference.es);
    expect(
      await _setPasswordError(),
      'No se pudo guardar tu contraseña. Inténtalo de nuevo.',
    );
  });
}
