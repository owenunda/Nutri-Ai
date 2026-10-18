import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Único archivo que conoce RevenueCat. El resto de la app usa PurchaseService,
// así las pruebas pueden cambiarlo por uno falso.

const kProEntitlement = 'nutrilife_pro';

enum PremiumPlan { monthly, yearly }

class PlanPrice {
  const PlanPrice({required this.priceString, required this.price});

  /// Precio con la moneda del país, listo para mostrar.
  final String priceString;
  final double price;
}

class PremiumOffer {
  const PremiumOffer({this.monthly, this.yearly});

  final PlanPrice? monthly;
  final PlanPrice? yearly;

  bool get isEmpty => monthly == null && yearly == null;

  PlanPrice? priceOf(PremiumPlan plan) => plan == PremiumPlan.monthly ? monthly : yearly;

  /// Cuánto ahorra el anual frente a doce meses del mensual, en %. Null si
  /// falta un precio o el ahorro es menor a 5%.
  int? get yearlySavingsPercent {
    final m = monthly?.price;
    final y = yearly?.price;
    if (m == null || y == null || m <= 0) return null;
    final percent = ((1 - y / (m * 12)) * 100).round();
    return percent >= 5 ? percent : null;
  }
}

enum PurchaseOutcome { success, cancelled, pending, alreadyOwned, notAllowed, storeUnavailable, failed }

enum RestoreOutcome { restored, nothingFound, failed }

/// No se pudieron cargar los precios (sin internet, sin offering, sin key).
class PurchaseLoadException implements Exception {
  const PurchaseLoadException();
}

abstract class PurchaseService {
  static PurchaseService instance = RevenueCatPurchaseService.fromEnvironment();

  /// false si la build no trae key: la pantalla premium dice "pagos pronto".
  bool get isEnabled;
  Future<void> init();
  Future<void> logIn(String userId);
  Future<void> logOut();
  Future<PremiumOffer> loadOffer();
  Future<PurchaseOutcome> purchase(PremiumPlan plan);
  Future<RestoreOutcome> restore();

  /// Página de la tienda para administrar o cancelar la suscripción.
  Future<String?> managementUrl();
}

class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this._apiKey);

  /// Las keys llegan por --dart-define. Hoy las dos son la de la Test Store.
  factory RevenueCatPurchaseService.fromEnvironment() {
    const androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
    const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
    if (kIsWeb) return RevenueCatPurchaseService('');
    if (Platform.isAndroid) return RevenueCatPurchaseService(androidKey);
    if (Platform.isIOS) return RevenueCatPurchaseService(iosKey);
    return RevenueCatPurchaseService('');
  }

  final String _apiKey;
  bool _configured = false;
  Package? _monthly;
  Package? _yearly;

  @override
  bool get isEnabled => _apiKey.isNotEmpty;

  bool get _ready => isEnabled && _configured;

  @override
  Future<void> init() async {
    if (!isEnabled || _configured) return;
    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
    } catch (error) {
      debugPrint('[purchases] no se pudo configurar RevenueCat: $error');
    }
  }

  @override
  Future<void> logIn(String userId) async {
    if (!_ready) return;
    try {
      await Purchases.logIn(userId);
    } catch (error) {
      debugPrint('[purchases] logIn falló: $error');
    }
  }

  @override
  Future<void> logOut() async {
    if (!_ready) return;
    try {
      // Cerrar la sesión de un usuario anónimo lanza error.
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } catch (error) {
      debugPrint('[purchases] logOut falló: $error');
    }
  }

  @override
  Future<PremiumOffer> loadOffer() async {
    if (!_ready) throw const PurchaseLoadException();
    try {
      final current = (await Purchases.getOfferings()).current;
      _monthly = current?.monthly;
      _yearly = current?.annual;
    } catch (error) {
      debugPrint('[purchases] no se pudo cargar el offering: $error');
      throw const PurchaseLoadException();
    }
    final offer = PremiumOffer(monthly: _priceOf(_monthly), yearly: _priceOf(_yearly));
    if (offer.isEmpty) throw const PurchaseLoadException();
    return offer;
  }

  static PlanPrice? _priceOf(Package? package) => package == null
      ? null
      : PlanPrice(priceString: package.storeProduct.priceString, price: package.storeProduct.price);

  @override
  Future<PurchaseOutcome> purchase(PremiumPlan plan) async {
    if (!_ready) return PurchaseOutcome.storeUnavailable;
    if (_monthly == null && _yearly == null) {
      try {
        await loadOffer();
      } on PurchaseLoadException {
        return PurchaseOutcome.storeUnavailable;
      }
    }
    final package = plan == PremiumPlan.monthly ? _monthly : _yearly;
    if (package == null) return PurchaseOutcome.storeUnavailable;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active.containsKey(kProEntitlement)
          ? PurchaseOutcome.success
          : PurchaseOutcome.failed;
    } on PlatformException catch (error) {
      return _outcomeFor(PurchasesErrorHelper.getErrorCode(error));
    }
  }

  static PurchaseOutcome _outcomeFor(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        PurchasesErrorCode.productAlreadyPurchasedError => PurchaseOutcome.alreadyOwned,
        PurchasesErrorCode.purchaseNotAllowedError => PurchaseOutcome.notAllowed,
        PurchasesErrorCode.storeProblemError ||
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError =>
          PurchaseOutcome.storeUnavailable,
        _ => PurchaseOutcome.failed,
      };

  @override
  Future<RestoreOutcome> restore() async {
    if (!_ready) return RestoreOutcome.failed;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(kProEntitlement)
          ? RestoreOutcome.restored
          : RestoreOutcome.nothingFound;
    } catch (error) {
      debugPrint('[purchases] restaurar falló: $error');
      return RestoreOutcome.failed;
    }
  }

  @override
  Future<String?> managementUrl() async {
    if (!_ready) return null;
    try {
      return (await Purchases.getCustomerInfo()).managementURL;
    } catch (error) {
      debugPrint('[purchases] no se pudo leer la managementURL: $error');
      return null;
    }
  }
}
