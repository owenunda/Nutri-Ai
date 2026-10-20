import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion.dart';

/// Hoja para elegir una opción del juego (una nutria, un lugar). Devuelve la
/// que se tocó, o null si se cierra.
Future<T?> showGamePickerSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<T> options,
  required T selected,
  required String Function(T option) label,
  required Widget Function(T option) preview,
}) {
  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: kSheetAnimation,
    // Con muchas opciones la hoja crece hasta el 85 % y el resto hace scroll.
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in options)
                    _OptionTile(
                      label: label(option),
                      preview: preview(option),
                      selected: option == selected,
                      onTap: () => Navigator.pop(sheetContext, option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 104,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primaryStart : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              SizedBox.square(dimension: 92, child: preview),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
