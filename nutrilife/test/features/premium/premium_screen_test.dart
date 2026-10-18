import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/features/premium/data/subscription_repository.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

class _FakeSubscriptions extends SubscriptionRepository {
  _FakeSubscriptions({this.fails = false}) : super(dio: Dio());

  final bool fails;
  int calls = 0;

  @override
  Future<SubscriptionState> sync() async {
    calls++;
    if (fails) throw const SubscriptionSyncException();
    return const SubscriptionState(plan: 'PRO', proSource: 'store');
  }
}

/// Abre la pantalla desde un botón para poder ver el pop con resultado.
Future<List<Object?>> _pump(
  WidgetTester tester, {
  required FakePurchaseService purchases,
  _FakeSubscriptions? subscriptions,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final results = <Object?>[];
  await tester.pumpWidget(l10nApp(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          results.add(await Navigator.of(context).push<bool>(MaterialPageRoute(
            builder: (_) => PremiumScreen(purchases: purchases, subscriptions: subscriptions ?? _FakeSubscriptions()),
          )));
        },
        child: const Text('abrir'),
      ),
    ),
  )));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('muestra los precios de la tienda y el ahorro', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(find.text('\$29.99 / año'), findsOneWidget);
    expect(find.text('\$4.99 / mes'), findsOneWidget);
    expect(find.text('Ahorra 50%'), findsOneWidget);
  });

  testWidgets('el anual viene elegido y se puede cambiar', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(find.byKey(const ValueKey('plan-yearly-selected')), findsOneWidget);
    await tester.tap(find.text('Mensual'));
    await tester.pump();
    expect(find.byKey(const ValueKey('plan-monthly-selected')), findsOneWidget);
  });

  testWidgets('si fallan los precios se puede reintentar', (tester) async {
    final purchases = FakePurchaseService(loadFails: true);
    await _pump(tester, purchases: purchases);

    expect(find.text('No pudimos cargar los precios.'), findsOneWidget);
    purchases.loadFails = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('\$29.99 / año'), findsOneWidget);
    expect(purchases.loadCalls, 2);
  });

  testWidgets('comprar con éxito sincroniza y cierra con true', (tester) async {
    final purchases = FakePurchaseService();
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(tester, purchases: purchases, subscriptions: subscriptions);

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(purchases.purchased, [PremiumPlan.yearly]);
    expect(subscriptions.calls, 1);
    expect(results, [true]);
    expect(find.text('¡Ya eres PRO!'), findsOneWidget);
  });

  testWidgets('si el sync falla avisa que tarda y cierra igual', (tester) async {
    final results = await _pump(tester, purchases: FakePurchaseService(), subscriptions: _FakeSubscriptions(fails: true));

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.text('Tu compra se registró. El PRO puede tardar unos minutos en activarse.'), findsOneWidget);
  });

  testWidgets('cancelar la compra no hace nada', (tester) async {
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(
      tester,
      purchases: FakePurchaseService(purchaseOutcome: PurchaseOutcome.cancelled),
      subscriptions: subscriptions,
    );

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(subscriptions.calls, 0);
    expect(results, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('pago pendiente avisa y no cierra', (tester) async {
    final results = await _pump(tester, purchases: FakePurchaseService(purchaseOutcome: PurchaseOutcome.pending));

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(results, isEmpty);
    expect(find.text('Tu pago está pendiente. El PRO se activa cuando la tienda lo confirme.'), findsOneWidget);
  });

  testWidgets('restaurar sin compras avisa', (tester) async {
    final purchases = FakePurchaseService(restoreOutcome: RestoreOutcome.nothingFound);
    final results = await _pump(tester, purchases: purchases);

    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(purchases.restoreCalls, 1);
    expect(results, isEmpty);
    expect(find.text('No encontramos compras para restaurar.'), findsOneWidget);
  });

  testWidgets('restaurar con éxito sincroniza y cierra', (tester) async {
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(tester, purchases: FakePurchaseService(), subscriptions: subscriptions);

    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(subscriptions.calls, 1);
    expect(results, [true]);
    expect(find.text('Recuperamos tu PRO.'), findsOneWidget);
  });

  testWidgets('sin key los pagos llegan pronto', (tester) async {
    final purchases = FakePurchaseService(isEnabled: false);
    await _pump(tester, purchases: purchases);

    expect(purchases.loadCalls, 0);
    await tester.tap(find.text('Suscribirme'));
    await tester.pump();
    expect(find.text('Los pagos llegan pronto'), findsOneWidget);
  });

  testWidgets('muestra el aviso de renovación automática', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(
      find.text('La suscripción se renueva automáticamente. Puedes cancelarla cuando quieras desde la tienda.'),
      findsOneWidget,
    );
    expect(find.text('Privacidad'), findsOneWidget);
  });
}
