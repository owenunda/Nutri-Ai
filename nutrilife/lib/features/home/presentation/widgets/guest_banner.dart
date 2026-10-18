import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Recuerda arriba del inicio que la cuenta es de invitado y cuándo se borra.
class GuestBanner extends StatelessWidget {
  const GuestBanner({
    super.key,
    required this.expiresAt,
    required this.onCreateAccount,
    this.now,
  });

  final DateTime expiresAt;
  final VoidCallback onCreateAccount;

  /// Solo para pruebas.
  final DateTime Function()? now;

  static const _ink = Color(0xFF8A5A00);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hoursLeft = expiresAt.difference((now ?? DateTime.now)()).inHours;
    final text = hoursLeft < 1
        ? l10n.homeGuestBannerSoon
        : l10n.homeGuestBanner(hoursLeft);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: _ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onCreateAccount,
            child: Text(
              l10n.homeGuestCreateAccount,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
