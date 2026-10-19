import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/api_routes.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Responde 200 con cabeceras de rate limit, como el backend.
class _RateLimitAdapter implements HttpClientAdapter {
  _RateLimitAdapter({required this.limit, required this.remaining});

  final int limit;
  final int remaining;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      'X-RateLimit-Limit': ['$limit'],
      'X-RateLimit-Remaining': ['$remaining'],
      'X-RateLimit-Reset': ['3591'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.rateLimit.clear();
    final original = DioClient.instance.httpClientAdapter;
    addTearDown(() {
      DioClient.instance.httpClientAdapter = original;
      DioClient.rateLimit.clear();
    });
  });

  test('las cabeceras del chat actualizan el contador de mensajes', () async {
    DioClient.instance.httpClientAdapter = _RateLimitAdapter(limit: 10, remaining: 7);

    await DioClient.instance.post(ApiRoutes.n8nChat);

    expect(DioClient.rateLimit.limit, 10);
    expect(DioClient.rateLimit.remaining, 7);
  });

  test('el límite de otra ruta no toca el contador del chat', () async {
    // POST /auth/guest manda su propio límite (5 por hora): no son mensajes.
    DioClient.instance.httpClientAdapter = _RateLimitAdapter(limit: 5, remaining: 1);

    await DioClient.instance.post(ApiRoutes.authGuest);
    await DioClient.instance.get(ApiRoutes.userProfile);

    expect(DioClient.rateLimit.hasInfo, isFalse);
  });

  test('el chat agotado no se pisa con el límite de otra ruta', () async {
    DioClient.instance.httpClientAdapter = _RateLimitAdapter(limit: 10, remaining: 0);
    await DioClient.instance.post(ApiRoutes.n8nChat);

    DioClient.instance.httpClientAdapter = _RateLimitAdapter(limit: 60, remaining: 59);
    await DioClient.instance.get(ApiRoutes.userProfile);

    expect(DioClient.rateLimit.limit, 10);
    expect(DioClient.rateLimit.isExhausted, isTrue);
  });
}
