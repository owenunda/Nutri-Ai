import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_quota_model.dart';

/// Va en lugar del input cuando ya no quedan mensajes por hoy.
/// Sin [onGoPremium] (usuarios PRO) no aparece el botón.
class ChatQuotaBlockedCard extends StatelessWidget {
  final ChatQuota quota;
  final VoidCallback? onGoPremium;

  const ChatQuotaBlockedCard({
    super.key,
    required this.quota,
    this.onGoPremium,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resetAt = quota.resetAt;
    final title = quota.unlimited
        ? l10n.chatQuotaFairUseTitle
        : l10n.chatQuotaExhaustedTitle(quota.limit ?? 0);

    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('chat-quota-blocked'),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/nutria_atenta.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (resetAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.chatQuotaResetsAt(
                        TimeOfDay.fromDateTime(resetAt).format(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (onGoPremium != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: onGoPremium,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryStart,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: Text(l10n.chatQuotaGoPremium),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
