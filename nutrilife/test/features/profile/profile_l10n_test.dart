import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/core/services/session_service.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';
import 'package:nutrilife/features/premium/presentation/widgets/premium_promo_card.dart';
import 'package:nutrilife/features/profile/data/profile_repository.dart';
import 'package:nutrilife/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:nutrilife/features/profile/presentation/screens/profile_screen.dart';
import 'package:nutrilife/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

/// Responde según el método HTTP y guarda las peticiones.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    this.getBody,
    this.deleteStatus = 200,
    this.deleteBody = const {'success': true},
  });

  final Object? getBody;
  final int deleteStatus;
  final Object deleteBody;
  final requests = <RequestOptions>[];

  RequestOptions get lastPut => requests.lastWhere((r) => r.method == 'PUT');

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = switch (options.method) {
      'GET' => (200, getBody),
      'PUT' => (200, const {'success': true}),
      _ => (deleteStatus, deleteBody),
    };
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

ProfileRepository _repoWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return ProfileRepository(dio: dio);
}

const _profileJson = {
  'success': true,
  'data': {
    'name': 'Ana',
    'email': 'ana@test.com',
    'age': 30,
    'weight': 70,
    'height': 170,
    'goal': 'Perder peso',
    'plan': 'Free',
    'createdAt': '2024-05-01T00:00:00.000Z',
    'hasPassword': true,
  },
};

UserProfile _profile({
  String? goal = 'Perder peso',
  String? sex,
  String email = 'ana@test.com',
}) {
  return UserProfile(
    name: 'Ana',
    email: email,
    age: 30,
    weight: 70,
    height: 170,
    goal: goal,
    sex: sex,
    plan: 'Free',
    createdAt: DateTime(2024, 5, 1),
    hasPassword: true,
  );
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _profileScreen(Locale locale) {
  return l10nApp(
    ProfileScreen(
      userName: 'Ana',
      onLogout: () {},
      repository: _repoWith(_FakeAdapter(getBody: _profileJson)),
    ),
    locale: locale,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ProfileScreen', () {
    testWidgets('el invitado no ve Eliminar cuenta', (tester) async {
      _tallScreen(tester);
      final originalPurchases = PurchaseService.instance;
      PurchaseService.instance = FakePurchaseService();
      addTearDown(() async {
        await SessionService.clear();
        PurchaseService.instance = originalPurchases;
      });
      await SessionService.save(token: 'jwt-guest', user: {'userId': 41, 'isGuest': true});

      await tester.pumpWidget(_profileScreen(const Locale('es')));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Eliminar cuenta'), findsNothing);
    });

    testWidgets('se ve en español', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(_profileScreen(const Locale('es')));
      await tester.pumpAndSettle();

      expect(find.text('Miembro Free desde 2024'), findsOneWidget);
      expect(find.text('EDAD'), findsOneWidget);
      expect(find.text('Objetivo nutricional'), findsOneWidget);
      expect(find.text('Bajar peso'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Eliminar cuenta'), findsOneWidget);
    });

    testWidgets('se ve en inglés', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(_profileScreen(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Free member since 2024'), findsOneWidget);
      expect(find.text('AGE'), findsOneWidget);
      expect(find.text('WEIGHT'), findsOneWidget);
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('Nutrition goal'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('Build muscle'), findsOneWidget);
      expect(find.text('Settings & reminders'), findsOneWidget);
      expect(find.text('Terms and conditions'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Objetivo nutricional'), findsNothing);
    });

    testWidgets('el diálogo de eliminar cuenta se ve en inglés', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(_profileScreen(const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your password to confirm.'), findsOneWidget);
    });
  });

  group('EditProfileScreen', () {
    testWidgets('el invitado ve "Cuenta de invitado" y no su correo falso', (tester) async {
      _tallScreen(tester);
      addTearDown(SessionService.clear);
      await SessionService.save(token: 'jwt-guest', user: {'userId': 41, 'isGuest': true});

      await tester.pumpWidget(l10nApp(
        EditProfileScreen(
          profile: _profile(email: 'guest-1b2c@guest.nutrilife.invalid'),
        ),
      ));
      await tester.pump();

      expect(find.text('Cuenta de invitado'), findsOneWidget);
      expect(find.textContaining('guest.nutrilife.invalid'), findsNothing);
    });

    testWidgets('se ve en inglés con los valores en inglés', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(l10nApp(
        EditProfileScreen(profile: _profile(sex: 'Mujer')),
        locale: const Locale('en'),
      ));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Nutrition details'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('30 years'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Mujer'), findsNothing);
      expect(find.text('Perder peso'), findsNothing);
    });

    testWidgets('en español muestra lo mismo de siempre', (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(l10nApp(
        EditProfileScreen(profile: _profile(goal: 'Ganar peso')),
      ));
      await tester.pump();

      expect(find.text('Datos nutricionales'), findsOneWidget);
      expect(find.text('30 años'), findsOneWidget);
      expect(find.text('Hombre'), findsOneWidget);
      expect(find.text('Subir de peso'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets(
      'elegir "Gain weight" en inglés manda "Ganar peso" y guarda "Mujer"',
      (tester) async {
        _tallScreen(tester);
        final adapter = _FakeAdapter();
        await tester.pumpWidget(l10nApp(
          EditProfileScreen(
            profile: _profile(sex: 'Hombre'),
            repository: _repoWith(adapter),
          ),
          locale: const Locale('en'),
        ));
        await tester.pump();

        await tester.tap(find.text('Lose weight'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gain weight'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Female').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();

        expect(adapter.lastPut.data['goal'], 'Ganar peso');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('profile_sex_ana@test.com'), 'Mujer');
      },
    );

    testWidgets('cambiar el peso pide confirmación en inglés', (tester) async {
      _tallScreen(tester);
      final adapter = _FakeAdapter();
      await tester.pumpWidget(l10nApp(
        EditProfileScreen(
          profile: _profile(),
          repository: _repoWith(adapter),
        ),
        locale: const Locale('en'),
      ));
      await tester.pump();

      await tester.tap(find.text('70.0 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30.0 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text("You're about to update your weight"), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('ProfileRepository', () {
    tearDown(() async {
      await LocaleState.instance.setPreference(LanguagePreference.system);
    });

    test('membershipText sigue el idioma', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      final profile = _profile();

      expect(profile.membershipText(es), 'Miembro Free desde 2024');
      expect(profile.membershipText(en), 'Free member since 2024');
      expect(
        UserProfile.fromJson({}).membershipText(es),
        'Miembro de NutriLife',
      );
      expect(
        UserProfile.fromJson({}).membershipText(en),
        'NutriLife member',
      );
    });

    test('el nombre por defecto sale en el idioma de la app', () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      expect(UserProfile.fromJson({}).name, 'User');
      await LocaleState.instance.setPreference(LanguagePreference.es);
      expect(UserProfile.fromJson({}).name, 'Usuario');
    });

    test('contraseña incorrecta al borrar: mensaje en inglés', () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      final adapter = _FakeAdapter(
        deleteStatus: 401,
        deleteBody: {
          'success': false,
          'error': {'code': 'INVALID_PASSWORD', 'details': <Object>[]},
        },
      );

      expect(
        () => _repoWith(adapter).deleteAccount(password: 'x', email: ''),
        throwsA(
          isA<ProfileException>().having(
            (error) => error.message,
            'message',
            "That password isn't correct.",
          ),
        ),
      );
    });

    test('sin mensaje del backend usa el texto local en el idioma actual',
        () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      final adapter = _FakeAdapter(getBody: {'success': false});

      expect(
        () => _repoWith(adapter).getProfile(),
        throwsA(
          isA<ProfileException>().having(
            (error) => error.message,
            'message',
            "We couldn't load your profile.",
          ),
        ),
      );
    });
  });

  group('Premium', () {
    testWidgets('la pantalla se ve en inglés', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        l10nApp(PremiumScreen(purchases: FakePurchaseService()),
            locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('NutriLife Premium'), findsOneWidget);
      expect(find.text('Take your nutrition to the next level'),
          findsOneWidget);
      expect(find.text('Full progress history'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('\$29.99 / year'), findsOneWidget);
      expect(find.text('\$4.99 / month'), findsOneWidget);
      expect(find.text('Save 50%'), findsOneWidget);
      expect(find.text('Subscribe'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);

      // Sin la key de RevenueCat la compra no se ofrece todavía.
      await tester.pumpWidget(
        l10nApp(
          PremiumScreen(
            key: const ValueKey('sin-key'),
            purchases: FakePurchaseService(isEnabled: false),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Subscribe'));
      await tester.pump();
      expect(find.text('Payments are coming soon'), findsOneWidget);
    });

    testWidgets('la tarjeta promocional se ve en los dos idiomas',
        (tester) async {
      await tester.pumpWidget(l10nApp(const Scaffold(body: PremiumPromoCard())));
      expect(find.text('Desbloquea tu progreso completo'), findsOneWidget);

      await tester.pumpWidget(l10nApp(
        const Scaffold(body: PremiumPromoCard()),
        locale: const Locale('en'),
      ));
      await tester.pump();
      expect(find.text('Unlock your full progress'), findsOneWidget);
    });
  });
}
