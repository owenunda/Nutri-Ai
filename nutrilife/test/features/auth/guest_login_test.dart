import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/core/services/session_service.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.enabled = true, this.fails = false}) : super(dio: Dio());

  final bool enabled;
  final bool fails;
  int guestCalls = 0;

  @override
  Future<bool> isGuestModeEnabled() async => enabled;

  @override
  Future<GoogleLoginResult> loginAsGuest() async {
    guestCalls++;
    if (fails) throw const AuthException('El modo invitado no está disponible.');
    // needsProfileSetup: true abre el setup, más liviano que el Dashboard.
    return const GoogleLoginResult(
      token: 'jwt-guest',
      user: {'userId': 41, 'name': 'Invitado', 'isGuest': true},
      needsProfileSetup: true,
      offerPasswordSetup: false,
    );
  }
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  final originalPurchases = PurchaseService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PurchaseService.instance = FakePurchaseService();
  });

  tearDown(() async {
    await SessionService.clear();
    PurchaseService.instance = originalPurchases;
  });

  testWidgets('sin modo invitado no hay botón', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository(enabled: false))));
    await tester.pumpAndSettle();

    expect(find.text('Entrar como invitado'), findsNothing);
  });

  testWidgets('la alerta explica la cuenta y Cancelar no crea nada', (tester) async {
    _tallScreen(tester);
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('• Es una cuenta de prueba con datos de ejemplo.'), findsOneWidget);
    expect(find.text('• Se borra en 24 horas, junto con todo lo que registres.'), findsOneWidget);
    expect(find.text('• Tiene el plan FREE y no puedes comprar PRO.'), findsOneWidget);
    expect(find.text('• Si quieres guardar tu progreso, crea una cuenta.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.guestCalls, 0);
    expect(SessionService.isGuest, isFalse);
  });

  testWidgets('Entrar crea la sesión de invitado', (tester) async {
    _tallScreen(tester);
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repo.guestCalls, 1);
    expect(SessionService.isGuest, isTrue);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('si falla, el error sale en el login', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository(fails: true))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('El modo invitado no está disponible.'), findsOneWidget);
  });

  testWidgets('el aviso de invitado vencido sale al abrir el login', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(
      LoginScreen(
        authRepository: _FakeAuthRepository(enabled: false),
        notice: 'Tu cuenta de invitado venció. Crea una cuenta para seguir.',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta de invitado venció. Crea una cuenta para seguir.'), findsOneWidget);
  });

  testWidgets('el botón se ve en inglés', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository()), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
