import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/locale_state.dart';
import '../../../../core/theme/app_theme.dart';

/// Cada idioma se escribe en su propio idioma, sin importar el de la app.
String languagePreferenceLabel(AppLocalizations l10n, LanguagePreference p) =>
    switch (p) {
      LanguagePreference.system => l10n.profileLanguageSystem,
      LanguagePreference.es => 'Español',
      LanguagePreference.en => 'English',
    };

Future<void> showLanguageSheet(BuildContext context, {LocaleState? state}) {
  final localeState = state ?? LocaleState.instance;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
    ),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                l10n.profileLanguageSheetTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final option in LanguagePreference.values)
              ListTile(
                title: Text(languagePreferenceLabel(l10n, option)),
                trailing: option == localeState.preference
                    ? const Icon(Icons.check_rounded, color: AppTheme.primaryStart)
                    : null,
                onTap: () async {
                  await localeState.setPreference(option);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
