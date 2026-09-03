import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';

class RateLimitChip extends StatelessWidget {
  const RateLimitChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DioClient.rateLimit,
      builder: (context, _) {
        final s = DioClient.rateLimit;
        if (!s.hasInfo || !s.isLow) return const SizedBox.shrink();

        final exhausted = s.isExhausted;
        final remaining = s.remaining ?? 0;
        final reset = s.resetSeconds ?? 0;

        final bg = exhausted
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFFFBEB);
        final fg = exhausted
            ? const Color(0xFFB91C1C)
            : const Color(0xFF92400E);
        final icon = exhausted ? Icons.block : Icons.timer_outlined;

        final text = exhausted
            ? 'Límite alcanzado · reintenta en ${reset}s'
            : 'Te quedan $remaining mensajes este minuto';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}