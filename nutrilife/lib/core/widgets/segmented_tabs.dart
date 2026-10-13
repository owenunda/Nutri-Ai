import 'package:flutter/material.dart';

/// Pestañas tipo píldora ("Mi nevera | Comunes"). La píldora blanca se
/// desliza hasta la pestaña elegida. [badges] muestra un contador al lado de
/// cada etiqueta cuando es mayor que 0.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final List<int>? badges;
  final int selected;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.badges,
  });

  static const _green = Color(0xFF0A6B3F);
  static const _slate = Color(0xFF64748B);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    // Respeta "reducir movimiento" del sistema.
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final count = labels.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: _curve,
              alignment: Alignment(count == 1 ? 0 : -1 + 2 * selected / (count - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++) _tab(context, i, duration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int index, Duration duration) {
    final active = index == selected;
    final badge = badges == null ? 0 : badges![index];
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: _curve,
                  // Se parte del estilo heredado para conservar la fuente de la app.
                  style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: active ? _green : _slate,
                      ),
                  child: Text(labels[index]),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
