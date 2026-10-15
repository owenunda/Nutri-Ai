import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/profile/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

ProfileRepository _repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return ProfileRepository(dio: dio);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Los mensajes locales salen en el idioma de la app: aquí, español.
    await LocaleState.instance.setPreference(LanguagePreference.es);
  });

  tearDown(() async {
    await LocaleState.instance.setPreference(LanguagePreference.system);
  });

  test('hasPassword viene del backend y si falta se asume true', () {
    expect(UserProfile.fromJson({'hasPassword': false}).hasPassword, isFalse);
    expect(UserProfile.fromJson({}).hasPassword, isTrue);
  });

  test('borrar con Google manda googleIdToken y no la contraseña', () async {
    final adapter = _FakeAdapter(200, {'success': true, 'data': null});

    await _repoWith(adapter).deleteAccount(googleIdToken: 'tok', email: '');

    expect(adapter.lastRequest!.method, 'DELETE');
    expect(adapter.lastRequest!.data, {'googleIdToken': 'tok'});
  });

  test('otra cuenta de Google: mensaje claro', () async {
    final adapter = _FakeAdapter(403, {
      'success': false,
      'message': 'Esa cuenta de Google no corresponde a este perfil.',
      'error': {'code': 'GOOGLE_ACCOUNT_MISMATCH', 'details': <Object>[]},
    });

    expect(
      () => _repoWith(adapter).deleteAccount(googleIdToken: 'tok', email: ''),
      throwsA(
        isA<ProfileException>().having(
          (error) => error.message,
          'message',
          'Esa cuenta de Google no corresponde a este perfil.',
        ),
      ),
    );
  });
}
