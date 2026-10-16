import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/locale_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion.dart';

/// Cada idioma se escribe en su propio idioma, sin importar el de la app.
String languagePreferenceLabel(AppLocalizations l10n, LanguagePreference p) =>
    switch (p) {
      LanguagePreference.system => l10n.profileLanguageSystem,
      LanguagePreference.es => 'Español',
      LanguagePreference.en => 'English',
    };

/// Panel para elegir el idioma. Mismo aspecto que los selectores de
/// `edit_profile_screen.dart`.
Future<void> showLanguageSheet(BuildContext context, {LocaleState? state}) {
  final localeState = state ?? LocaleState.instance;
  return showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: kSheetAnimation,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      // Evita que un doble toque cierre también la pantalla de abajo.
      var closing = false;
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  l10n.profileLanguageSheetTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final option in LanguagePreference.values) ...[
                _LanguageOption(
                  label: languagePreferenceLabel(l10n, option),
                  selected: option == localeState.preference,
                  onTap: () {
                    if (closing) return;
                    closing = true;
                    Navigator.of(sheetContext).pop();
                    localeState.setPreference(option);
                  },
                ),
                if (option != LanguagePreference.values.last)
                  const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryStart.withValues(alpha: 0.10)
                : const Color(0xFFF0F3F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppTheme.primaryStart,
                        size: 22,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
