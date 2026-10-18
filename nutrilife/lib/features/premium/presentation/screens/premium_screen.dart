import 'package:flutter/material.dart';
import '../../../legal/data/legal_documents.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';
import '../../data/subscription_repository.dart';
import '../../../../core/ads/ads_service.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_theme.dart';

List<String> premiumBenefits(AppLocalizations l10n) => [
      l10n.premiumBenefitChat,
      l10n.premiumBenefitProgress,
      l10n.premiumBenefitPlans,
      l10n.premiumBenefitRecipes,
    ];

/// Pantalla de compra del PRO. Cierra con `true` cuando el usuario queda PRO.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.purchases, this.subscriptions});

  final PurchaseService? purchases;
  final SubscriptionRepository? subscriptions;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final PurchaseService _purchases = widget.purchases ?? PurchaseService.instance;
  late final SubscriptionRepository _subscriptions = widget.subscriptions ?? SubscriptionRepository();

  PremiumPlan _plan = PremiumPlan.yearly;
  PremiumOffer? _offer;
  bool _loading = false;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_purchases.isEnabled) _loadOffer();
  }

  Future<void> _loadOffer() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final offer = await _purchases.loadOffer();
      if (!mounted) return;
      setState(() => _offer = offer);
    } on PurchaseLoadException {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _subscribe() async {
    final l10n = context.l10n;
    if (!_purchases.isEnabled) return _say(l10n.premiumPaymentsSoon);

    setState(() => _busy = true);
    final PurchaseOutcome outcome;
    try {
      outcome = await _purchases.purchase(_plan);
    } finally {
      // Pase lo que pase, el botón no se queda girando.
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    switch (outcome) {
      case PurchaseOutcome.success:
        await _activate(l10n.premiumWelcome);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        _say(l10n.premiumPending);
      case PurchaseOutcome.alreadyOwned:
        _say(l10n.premiumAlreadyOwned);
      case PurchaseOutcome.notAllowed:
        _say(l10n.premiumNotAllowed);
      case PurchaseOutcome.storeUnavailable:
        _say(l10n.premiumStoreUnavailable);
      case PurchaseOutcome.failed:
        _say(l10n.premiumPurchaseError);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    if (!_purchases.isEnabled) return _say(l10n.premiumPaymentsSoon);

    setState(() => _busy = true);
    final RestoreOutcome outcome;
    try {
      outcome = await _purchases.restore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    switch (outcome) {
      case RestoreOutcome.restored:
        await _activate(l10n.premiumRestored);
      case RestoreOutcome.nothingFound:
        _say(l10n.premiumRestoreNone);
      case RestoreOutcome.failed:
        _say(l10n.premiumStoreUnavailable);
    }
  }

  // La tienda ya cobró: se le avisa al backend y se cierra. Si el backend no
  // responde, el webhook de RevenueCat activa el PRO después.
  Future<void> _activate(String successMessage) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    var message = successMessage;
    try {
      final state = await _subscriptions.sync();
      AdsService.instance.setPlan(state.plan);
      // La tienda cobró pero el backend todavía no ve el PRO: no decir que ya está.
      if (state.plan != 'PRO') message = l10n.premiumSyncDelayed;
    } on SubscriptionSyncException {
      message = l10n.premiumSyncDelayed;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _say(message);
    Navigator.of(context).pop(true);
  }

  String? _priceText(PremiumPlan plan) {
    final price = _offer?.priceOf(plan)?.priceString;
    if (price == null) return null;
    final l10n = context.l10n;
    return plan == PremiumPlan.yearly ? l10n.premiumPricePerYear(price) : l10n.premiumPricePerMonth(price);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savings = _offer?.yearlySavingsPercent;
    final canBuy = !_busy && (!_purchases.isEnabled || (_offer?.priceOf(_plan) != null));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Center(
            child: ClipOval(
              child: Image.asset('assets/images/nutria_atenta.png', width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premiumTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final benefit in premiumBenefits(l10n))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryStart),
                  const SizedBox(width: 12),
                  Expanded(child: Text(benefit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _PlanCard(
            title: l10n.premiumPlanYearly,
            price: _priceText(PremiumPlan.yearly),
            loading: _loading,
            badge: savings == null ? null : l10n.premiumSaveBadge(savings),
            selected: _plan == PremiumPlan.yearly,
            selectedKey: const ValueKey('plan-yearly-selected'),
            onTap: () => setState(() => _plan = PremiumPlan.yearly),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: l10n.premiumPlanMonthly,
            price: _priceText(PremiumPlan.monthly),
            loading: _loading,
            selected: _plan == PremiumPlan.monthly,
            selectedKey: const ValueKey('plan-monthly-selected'),
            onTap: () => setState(() => _plan = PremiumPlan.monthly),
          ),
          if (_loadFailed) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(l10n.premiumLoadError, style: const TextStyle(color: AppTheme.onSurfaceVariant))),
                TextButton(onPressed: _loadOffer, child: Text(l10n.commonRetry)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: canBuy ? _subscribe : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(l10n.premiumSubscribe),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.premiumAutoRenewNote,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: _busy ? null : _restore, child: Text(l10n.premiumRestore)),
              const Text('·'),
              TextButton(
                onPressed: () => openLegalDocument(context, LegalDocuments.terms),
                child: Text(l10n.premiumTerms),
              ),
              const Text('·'),
              TextButton(
                onPressed: () => openLegalDocument(context, LegalDocuments.privacy),
                child: Text(l10n.premiumPrivacy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String? price;
  final bool loading;
  final String? badge;
  final bool selected;
  final Key selectedKey;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    this.price,
    this.loading = false,
    this.badge,
    required this.selected,
    required this.selectedKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        key: selected ? selectedKey : null,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryStart : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.primaryStart : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (price != null)
                    Text(price!, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: AppTheme.primaryStart, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
