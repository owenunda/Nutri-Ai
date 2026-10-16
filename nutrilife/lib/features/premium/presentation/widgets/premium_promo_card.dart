import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/premium_screen.dart';

class PremiumPromoCard extends StatelessWidget {
  const PremiumPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryStart),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.premiumPromoTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryStart),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryStart),
          ],
        ),
      ),
    );
  }
}
