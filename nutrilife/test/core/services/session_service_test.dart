import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/core/services/session_service.dart';

import '../../helpers/fake_purchase_service.dart';

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
  final originalPurchases = PurchaseService.instance;
  late FakePurchaseService purchases;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DioClient.authToken = null;
    purchases = FakePurchaseService();
    PurchaseService.instance = purchases;
  });

  tearDown(() async {
    DioClient.authToken = null;
    await SessionService.clear();
    PurchaseService.instance = originalPurchases;
  });

  test('save logs in to RevenueCat with the backend userId', () async {
    await SessionService.save(token: 'jwt-token', user: {'userId': 8, 'name': 'Ana'});

    expect(purchases.loggedIn, ['8']);
  });

  test('restoring a stored session also logs in to RevenueCat', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'jwt-token',
      'auth_user': '{"userId":8,"name":"Ana"}',
    });

    final restored = await SessionService.restore();
    await Future<void>.delayed(Duration.zero);

    expect(restored, isNotNull);
    expect(purchases.loggedIn, ['8']);
  });

  test('clear logs out of RevenueCat once', () async {
    await SessionService.clear();

    expect(purchases.logOutCalls, 1);
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

  test('un invitado no se ata a RevenueCat', () async {
    await SessionService.save(
      token: 'jwt-guest',
      user: {'userId': 41, 'isGuest': true, 'guestExpiresAt': '2026-10-19T15:00:00.000Z'},
    );

    expect(purchases.loggedIn, isEmpty);
    expect(SessionService.isGuest, isTrue);
    expect(SessionService.guestExpiresAt, DateTime.utc(2026, 10, 19, 15).toLocal());
  });

  test('una cuenta normal no es invitado', () async {
    await SessionService.save(token: 'jwt', user: {'userId': 8});

    expect(SessionService.isGuest, isFalse);
    expect(SessionService.guestExpiresAt, isNull);
  });

  test('restaurar la sesión recuerda que es invitado y clear lo olvida', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'jwt-guest',
      'auth_user': '{"userId":41,"isGuest":true,"guestExpiresAt":"2026-10-19T15:00:00.000Z"}',
    });

    await SessionService.restore();
    expect(SessionService.isGuest, isTrue);

    await SessionService.clear();
    expect(SessionService.isGuest, isFalse);
  });
}
