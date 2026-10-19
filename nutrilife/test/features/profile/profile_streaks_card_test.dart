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

/// Responde la racha calórica que calcula el backend con toda la historia.
class _StreakServer implements HttpClientAdapter {
  _StreakServer(this.streak);

  final Map<String, dynamic> streak;
  RequestOptions? lastStreakRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/stats/calorie-streak') {
      return _json(404, {'success': false, 'message': 'not found'});
    }
    lastStreakRequest = options;
    return _json(200, {'success': true, 'data': streak});
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

Future<void> _pumpCard(WidgetTester tester) async {
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
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('si falla el agua, la racha de calorías sigue visible', (tester) async {
    final streaks = _StreakServer({'current': 2, 'best': 2, 'dailyLimit': 2000});
    DioClient.instance.httpClientAdapter =
        FakeHydrationServer(fallback: streaks)..failing = true;

    await _pumpCard(tester);

    expect(find.byKey(const ValueKey('profile-streaks-card')), findsOneWidget);
    expect(find.text('No se pudieron cargar tus rachas.'), findsNothing);
    // Calorías: 2 días seguidos. Agua: sin dato, "--".
    expect(find.text('2 días'), findsOneWidget);
    expect(find.text('-- días'), findsOneWidget);
  });

  testWidgets('la racha calórica usa toda la historia, sin tope de 7', (tester) async {
    final streaks = _StreakServer({'current': 12, 'best': 15, 'dailyLimit': 2000});
    DioClient.instance.httpClientAdapter = FakeHydrationServer(fallback: streaks);

    await _pumpCard(tester);

    expect(find.text('12 días'), findsOneWidget);
    expect(find.text('actual · mejor 15'), findsOneWidget);
    expect(find.textContaining('7+'), findsNothing);
    expect(
      streaks.lastStreakRequest!.queryParameters['date'],
      localDateString(DateTime.now()),
    );
    expect(
      find.text('Un día cuenta si comes dentro del rango de tu meta.'),
      findsOneWidget,
    );
  });

  testWidgets('sin meta calórica pide completar el perfil', (tester) async {
    final streaks = _StreakServer({'current': null, 'best': null, 'dailyLimit': null});
    DioClient.instance.httpClientAdapter = FakeHydrationServer(fallback: streaks);

    await _pumpCard(tester);

    expect(
      find.text('Completa tu edad, altura y peso para calcular esta racha.'),
      findsOneWidget,
    );
  });
}
