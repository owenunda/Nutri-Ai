import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../data/models/chat_quota_model.dart';

/// "2 de 3 mensajes hoy". Solo para FREE: PRO y ADMIN no lo ven.
class ChatQuotaChip extends StatelessWidget {
  final ChatQuota? quota;

  const ChatQuotaChip({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final q = quota;
    final limit = q?.limit;
    final remaining = q?.remaining;
    if (q == null || q.unlimited || limit == null || remaining == null) {
      return const SizedBox.shrink();
    }

    // Ámbar cuando queda el último y rojo cuando no queda ninguno.
    final (bg, fg) = remaining <= 0
        ? (const Color(0xFFFEE2E2), const Color(0xFFB91C1C))
        : remaining == 1
            ? (const Color(0xFFFFFBEB), const Color(0xFF92400E))
            : (const Color(0xFFF1F5F9), const Color(0xFF475569));

    return Container(
      key: const ValueKey('chat-quota-chip'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            context.l10n.chatQuotaRemaining(remaining, limit),
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
