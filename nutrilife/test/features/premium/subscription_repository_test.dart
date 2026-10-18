import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/premium/data/subscription_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Map<String, Object?> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

SubscriptionRepository _repo(_Adapter adapter) =>
    SubscriptionRepository(dio: Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter);

void main() {
  test('sync devuelve el plan efectivo', () async {
    final adapter = _Adapter(200, {
      'success': true,
      'data': {'plan': 'PRO', 'proUntil': '2026-11-17T16:00:00.000Z', 'proSource': 'store'},
    });

    final state = await _repo(adapter).sync();

    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/subscription/sync');
    expect(state.plan, 'PRO');
    expect(state.proSource, 'store');
    expect(state.proUntil, DateTime.utc(2026, 11, 17, 16).toLocal());
  });

  test('un 502 lanza SubscriptionSyncException', () async {
    final adapter = _Adapter(502, {'success': false, 'message': 'x'});

    expect(_repo(adapter).sync(), throwsA(isA<SubscriptionSyncException>()));
  });
}
