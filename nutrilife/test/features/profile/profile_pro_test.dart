import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/profile/data/profile_repository.dart';
import 'package:nutrilife/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

/// Devuelve el perfil indicado para cualquier petición.
class _ProfileAdapter implements HttpClientAdapter {
  _ProfileAdapter(this.profile);

  final Map<String, Object?> profile;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': profile}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _profileJson({required String plan, String? proUntil, String? proSource}) => {
      'name': 'Ana',
      'email': 'ana@test.com',
      'age': 30,
      'weight': 70,
      'height': 170,
      'goal': 'Perder peso',
      'plan': plan,
      'proUntil': proUntil,
      'proSource': proSource,
      'createdAt': '2024-05-01T00:00:00.000Z',
      'hasPassword': true,
    };

Future<void> _pumpProfile(
  WidgetTester tester,
  Map<String, Object?> profile, {
  Locale locale = const Locale('es'),
  FakePurchaseService? purchases,
}) async {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _ProfileAdapter(profile);
  // En la app el perfil vive dentro del Scaffold del dashboard; aquí el aviso lo necesita.
  await tester.pumpWidget(l10nApp(
    Scaffold(body: ProfileScreen(
      userName: 'Ana',
      onLogout: () {},
      repository: ProfileRepository(dio: dio),
      purchases: purchases ?? FakePurchaseService(),
    )),
    locale: locale,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lee proUntil del perfil', () {
    final profile = UserProfile.fromJson(
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z'),
    );

    expect(profile.isPro, isTrue);
    expect(profile.proUntil, DateTime.utc(2026, 11, 24, 12).toLocal());
  });

  test('lee proSource del perfil', () {
    final store = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'store'));
    final both = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'both'));
    final gift = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'gift'));

    expect(store.proSource, 'store');
    expect(store.hasStoreSubscription, isTrue);
    expect(both.hasStoreSubscription, isTrue);
    expect(gift.hasStoreSubscription, isFalse);
  });

  testWidgets('PRO con fecha muestra hasta cuándo dura', (tester) async {
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z'),
    );

    expect(find.text('Activo hasta el 24 nov 2026'), findsOneWidget);
    expect(find.text('Planes y beneficios'), findsNothing);
  });

  testWidgets('PRO con fecha en inglés', (tester) async {
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z'),
      locale: const Locale('en'),
    );

    expect(find.text('Active until Nov 24, 2026'), findsOneWidget);
  });

  testWidgets('PRO sin vencimiento lo dice', (tester) async {
    await _pumpProfile(tester, _profileJson(plan: 'PRO'));

    expect(find.text('Activo sin vencimiento'), findsOneWidget);
  });

  testWidgets('FREE sigue viendo planes y beneficios', (tester) async {
    await _pumpProfile(tester, _profileJson(plan: 'FREE'));

    expect(find.text('Planes y beneficios'), findsOneWidget);
    expect(find.textContaining('Activo'), findsNothing);
  });

  testWidgets('PRO pagado: tocar la fila pide la página de la tienda', (tester) async {
    final purchases = FakePurchaseService(url: null);
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z', proSource: 'store'),
      purchases: purchases,
    );

    await tester.tap(find.text('Activo hasta el 24 nov 2026'));
    await tester.pump();

    expect(purchases.managementUrlCalls, 1);
    expect(find.text('Administra tu suscripción desde la tienda de tu teléfono.'), findsOneWidget);
  });

  testWidgets('PRO regalado: la fila no hace nada', (tester) async {
    final purchases = FakePurchaseService();
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z', proSource: 'gift'),
      purchases: purchases,
    );

    await tester.tap(find.text('Activo hasta el 24 nov 2026'));
    await tester.pump();

    expect(purchases.managementUrlCalls, 0);
  });
}
