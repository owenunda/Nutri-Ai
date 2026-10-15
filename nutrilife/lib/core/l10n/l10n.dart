import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../state/locale_state.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Traducciones para código sin BuildContext (repositorios, modelos).
/// Usa el idioma efectivo de LocaleState.
AppLocalizations get currentL10n =>
    lookupAppLocalizations(Locale(LocaleState.instance.languageCode));
