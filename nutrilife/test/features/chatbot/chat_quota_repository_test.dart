import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Responde con el status y el body indicados y recuerda la ruta pedida.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, this.body);

  final int status;
  final Object body;
  String? lastPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatRepository _repo(_StatusAdapter adapter) => ChatRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter,
    );

const _freeQuota = {
  'plan': 'FREE',
  'unlimited': false,
  'limit': 3,
  'used': 1,
  'remaining': 2,
  'resetAt': '2026-10-18T05:00:00.000Z',
  'exhausted': false,
};

Map<String, Object?> _quotaError(String code, Map<String, Object?> quota) => {
      'success': false,
      'message': 'Usaste tus 3 mensajes de hoy con el Chef IA.',
      'error': {'code': code, 'details': []},
      'data': {'quota': quota},
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleState.instance.setPreference(LanguagePreference.es);
  });

  group('ChatQuota.fromMap', () {
    test('lee la cuota FREE', () {
      final quota = ChatQuota.fromMap(_freeQuota)!;
      expect(quota.unlimited, isFalse);
      expect(quota.limit, 3);
      expect(quota.used, 1);
      expect(quota.remaining, 2);
      expect(quota.exhausted, isFalse);
      expect(quota.resetAt, DateTime.utc(2026, 10, 18, 5).toLocal());
    });

    test('lee la cuota PRO sin números', () {
      final quota = ChatQuota.fromMap({
        'plan': 'PRO',
        'unlimited': true,
        'limit': null,
        'used': null,
        'remaining': null,
        'resetAt': '2026-10-18T05:00:00.000Z',
        'exhausted': false,
      })!;
      expect(quota.unlimited, isTrue);
      expect(quota.limit, isNull);
      expect(quota.remaining, isNull);
    });

    test('algo que no es un mapa es null', () {
      expect(ChatQuota.fromMap(null), isNull);
      expect(ChatQuota.fromMap('x'), isNull);
    });
  });

  test('la respuesta del chat trae la cuota', () async {
    final repo = _repo(_StatusAdapter(200, {
      'success': true,
      'data': {'type': 'CHAT', 'message': 'hola', 'recipe': null, 'quota': _freeQuota},
    }));

    final reply = await repo.sendMessage('hola');

    expect(reply.quota?.remaining, 2);
  });

  test('un 429 CHAT_DAILY_LIMIT es ChatQuotaExceededException', () async {
    final repo = _repo(_StatusAdapter(
      429,
      _quotaError('CHAT_DAILY_LIMIT', {..._freeQuota, 'used': 3, 'remaining': 0, 'exhausted': true}),
    ));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(isA<ChatQuotaExceededException>()
          .having((e) => e.quota.remaining, 'remaining', 0)
          .having((e) => e.isFairUse, 'isFairUse', isFalse)),
    );
  });

  test('un 429 CHAT_FAIR_USE_LIMIT es de uso justo', () async {
    final repo = _repo(_StatusAdapter(
      429,
      _quotaError('CHAT_FAIR_USE_LIMIT', {
        'plan': 'PRO',
        'unlimited': true,
        'limit': null,
        'used': null,
        'remaining': null,
        'resetAt': '2026-10-18T05:00:00.000Z',
        'exhausted': true,
      }),
    ));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(isA<ChatQuotaExceededException>().having((e) => e.isFairUse, 'isFairUse', isTrue)),
    );
  });

  test('el 429 por minuto no es de cuota', () async {
    final repo = _repo(_StatusAdapter(429, {
      'success': false,
      'message': 'Has superado el límite de solicitudes.',
      'error': {'code': 'RATE_LIMIT_EXCEEDED', 'details': []},
    }));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(predicate((e) => e is! ChatQuotaExceededException)),
    );
  });

  test('getQuota pide /chat/quota y la lee', () async {
    final adapter = _StatusAdapter(200, {'success': true, 'data': _freeQuota});

    final quota = await _repo(adapter).getQuota();

    expect(adapter.lastPath, '/chat/quota');
    expect(quota?.remaining, 2);
  });

  test('getQuota devuelve null si el backend falla', () async {
    final adapter = _StatusAdapter(500, {'success': false, 'message': 'x'});

    expect(await _repo(adapter).getQuota(), isNull);
  });
}
