import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'NutriAI',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: AppTheme.primaryStart,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const Icon(
            Icons.notifications_rounded,
            color: AppTheme.onSurfaceVariant,
            size: 26,
          ),
        ],
      ),
    );
  }
}
