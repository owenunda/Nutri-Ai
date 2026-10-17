import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/utils/local_date.dart';
import 'package:nutrilife/features/profile/presentation/widgets/profile_streaks_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_hydration_server.dart';
import '../../helpers/l10n_app.dart';

/// Responde lo mínimo que pide la pantalla de progreso: perfil, historial
/// físico y la semana con dos días dentro de la meta calórica.
class _ProgressServer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final now = DateTime.now();
    final data = switch (options.path) {
      '/user/profile' => <String, dynamic>{'name': 'Ana'},
      '/user/physical/history' => <dynamic>[],
      '/stats/week' => <String, dynamic>{
        'dailyLimit': 2000,
        'average': 1500,
        'daysOnTarget': 2,
        'days': [
          for (final back in [1, 0])
            {
              'date': localDateString(now.subtract(Duration(days: back))),
              'totalConsumed': 1500,
            },
        ],
      },
      _ => null,
    };
    if (data == null) return _json(404, {'success': false, 'message': 'not found'});
    return _json(200, {'success': true, 'data': data});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('si falla el agua, la racha de calorías sigue visible', (tester) async {
    final server = FakeHydrationServer(fallback: _ProgressServer())..failing = true;
    DioClient.instance.httpClientAdapter = server;

    await tester.pumpWidget(
      l10nApp(
        const Scaffold(
          body: SingleChildScrollView(
            child: ProfileStreaksCard(accountId: 'streaks@example.com'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-streaks-card')), findsOneWidget);
    expect(find.text('No se pudieron cargar tus rachas.'), findsNothing);
    // Calorías: 2 días seguidos. Agua: sin dato, "--".
    expect(find.text('2 días'), findsOneWidget);
    expect(find.text('-- días'), findsOneWidget);
  });
}
