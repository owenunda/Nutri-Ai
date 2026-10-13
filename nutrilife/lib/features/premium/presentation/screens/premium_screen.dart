import 'package:flutter/material.dart';
import '../../../legal/data/legal_documents.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';
import '../../../../core/theme/app_theme.dart';

// Precios y textos de ejemplo: todavía no hay cobro.
const kPremiumMonthlyPrice = '\$4.99';
const kPremiumYearlyPrice = '\$29.99';
const kPremiumBenefits = [
  'Chef IA sin límite de mensajes',
  'Historial de progreso completo',
  'Planes de comida semanales',
  'Recetas guardadas sin límite',
];

enum _Plan { monthly, yearly }

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  _Plan _plan = _Plan.yearly;

  void _soon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Los pagos llegan pronto')));
  }

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset('assets/images/nutria_logo.png', width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NutriLife Premium',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lleva tu alimentación al siguiente nivel',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final benefit in kPremiumBenefits)
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
            title: 'Anual',
            price: '$kPremiumYearlyPrice / año',
            badge: 'Ahorra 50%',
            selected: _plan == _Plan.yearly,
            selectedKey: const ValueKey('plan-yearly-selected'),
            onTap: () => setState(() => _plan = _Plan.yearly),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Mensual',
            price: '$kPremiumMonthlyPrice / mes',
            selected: _plan == _Plan.monthly,
            selectedKey: const ValueKey('plan-monthly-selected'),
            onTap: () => setState(() => _plan = _Plan.monthly),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _soon,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: const Text('Empezar 7 días gratis'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: _soon, child: const Text('Restaurar compras')),
              const Text('·'),
              TextButton(
                onPressed: () => openLegalDocument(context, LegalDocuments.terms),
                child: const Text('Términos'),
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
  final String price;
  final String? badge;
  final bool selected;
  final Key selectedKey;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
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
                  Text(price, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
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
