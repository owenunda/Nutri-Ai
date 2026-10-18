import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';

void main() {
  const monthly = PlanPrice(priceString: '\$4.99', price: 4.99);
  const yearly = PlanPrice(priceString: '\$29.99', price: 29.99);

  test('el anual ahorra 50% frente a doce meses', () {
    expect(const PremiumOffer(monthly: monthly, yearly: yearly).yearlySavingsPercent, 50);
  });

  test('sin uno de los dos precios no hay ahorro', () {
    expect(const PremiumOffer(yearly: yearly).yearlySavingsPercent, isNull);
  });

  test('un ahorro menor a 5% no se muestra', () {
    const almostSame = PlanPrice(priceString: '\$58', price: 58);
    expect(const PremiumOffer(monthly: monthly, yearly: almostSame).yearlySavingsPercent, isNull);
  });

  test('priceOf e isEmpty', () {
    const offer = PremiumOffer(monthly: monthly);
    expect(offer.priceOf(PremiumPlan.monthly), monthly);
    expect(offer.priceOf(PremiumPlan.yearly), isNull);
    expect(offer.isEmpty, isFalse);
    expect(const PremiumOffer().isEmpty, isTrue);
  });

  test('sin key las compras quedan apagadas', () {
    expect(RevenueCatPurchaseService('').isEnabled, isFalse);
    expect(RevenueCatPurchaseService('test_abc').isEnabled, isTrue);
  });
}
