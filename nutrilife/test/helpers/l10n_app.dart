import 'package:flutter/material.dart';
import 'package:nutrilife/l10n/app_localizations.dart';

/// MaterialApp con las traducciones de la app. Por defecto en español, para
/// que los `find.text` de los tests sigan con los textos de siempre.
Widget l10nApp(Widget home, {Locale locale = const Locale('es')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}
