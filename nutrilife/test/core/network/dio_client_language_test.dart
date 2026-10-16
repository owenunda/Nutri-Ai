import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CaptureAdapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final original = DioClient.instance.httpClientAdapter;
    adapter = _CaptureAdapter();
    DioClient.instance.httpClientAdapter = adapter;
    addTearDown(() => DioClient.instance.httpClientAdapter = original);
  });

  test('manda el idioma elegido en Accept-Language', () async {
    await LocaleState.instance.setPreference(LanguagePreference.en);
    await DioClient.instance.get('/stats');
    expect(adapter.last!.headers['Accept-Language'], 'en');

    await LocaleState.instance.setPreference(LanguagePreference.es);
    await DioClient.instance.get('/stats');
    expect(adapter.last!.headers['Accept-Language'], 'es');
  });
}
