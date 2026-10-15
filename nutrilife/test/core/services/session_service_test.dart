import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/services/session_service.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.authToken = null;
  });

  tearDown(() async {
    DioClient.authToken = null;
    await SessionService.clear();
  });

  test('restoring a saved session also restores the request token', () async {
    const user = {'userId': 8, 'name': 'Ana'};
    await SessionService.save(token: 'jwt-token', user: user);
    DioClient.authToken = null;

    final restored = await SessionService.restore();

    expect(restored?.token, 'jwt-token');
    expect(restored?.user, user);
    expect(DioClient.authToken, 'jwt-token');
  });

  test('clears incomplete or malformed persisted sessions', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'jwt-token',
      'auth_user': '{invalid json',
    });

    final restored = await SessionService.restore();
    final prefs = await SharedPreferences.getInstance();

    expect(restored, isNull);
    expect(DioClient.authToken, isNull);
    expect(prefs.containsKey('auth_token'), isFalse);
    expect(prefs.containsKey('auth_user'), isFalse);
  });

  test('sends Bearer token on private API calls, not login requests', () async {
    final adapter = _CapturingAdapter();
    final previousAdapter = DioClient.instance.httpClientAdapter;
    DioClient.instance.httpClientAdapter = adapter;
    DioClient.authToken = 'jwt-token';

    try {
      await DioClient.instance.get('/private-resource');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');

      await DioClient.instance.get('/auth/login');
      expect(adapter.request?.headers.containsKey('Authorization'), isFalse);
    } finally {
      DioClient.instance.httpClientAdapter = previousAdapter;
    }
  });
}
