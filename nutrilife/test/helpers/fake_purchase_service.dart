import 'package:nutrilife/core/services/purchase_service.dart';

/// PurchaseService configurable para las pruebas de widgets.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    this.isEnabled = true,
    this.offer = const PremiumOffer(
      monthly: PlanPrice(priceString: '\$4.99', price: 4.99),
      yearly: PlanPrice(priceString: '\$29.99', price: 29.99),
    ),
    this.loadFails = false,
    this.purchaseOutcome = PurchaseOutcome.success,
    this.restoreOutcome = RestoreOutcome.restored,
    this.url,
  });

  @override
  final bool isEnabled;
  PremiumOffer offer;
  bool loadFails;
  PurchaseOutcome purchaseOutcome;
  RestoreOutcome restoreOutcome;
  String? url;

  final List<PremiumPlan> purchased = [];
  int loadCalls = 0;
  int restoreCalls = 0;
  int managementUrlCalls = 0;
  final List<String> loggedIn = [];
  int logOutCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> logIn(String userId) async => loggedIn.add(userId);

  @override
  Future<void> logOut() async => logOutCalls++;

  @override
  Future<PremiumOffer> loadOffer() async {
    loadCalls++;
    if (loadFails) throw const PurchaseLoadException();
    return offer;
  }

  @override
  Future<PurchaseOutcome> purchase(PremiumPlan plan) async {
    purchased.add(plan);
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async {
    restoreCalls++;
    return restoreOutcome;
  }

  @override
  Future<String?> managementUrl() async {
    managementUrlCalls++;
    return url;
  }
}
