import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LanguagePreference { system, es, en }

/// Idioma de la app. Sigue el patrón de BotMoodState: un ChangeNotifier
/// compartido que MaterialApp escucha, sin meter provider en el proyecto.
/// La red lo lee para mandar Accept-Language al backend.
class LocaleState extends ChangeNotifier {
  LocaleState({Locale Function()? deviceLocale})
      : _deviceLocale =
            deviceLocale ?? (() => PlatformDispatcher.instance.locale);

  static final LocaleState instance = LocaleState();

  static const _prefsKey = 'app_language';
  static const supportedCodes = ['es', 'en'];

  final Locale Function() _deviceLocale;
  LanguagePreference _preference = LanguagePreference.system;

  LanguagePreference get preference => _preference;

  /// `null` deja que Flutter elija según el teléfono.
  Locale? get locale => switch (_preference) {
        LanguagePreference.system => null,
        LanguagePreference.es => const Locale('es'),
        LanguagePreference.en => const Locale('en'),
      };

  /// Idioma efectivo: el elegido o, con `system`, el del teléfono si está
  /// soportado. Si no, inglés.
  String get languageCode {
    final chosen = locale;
    if (chosen != null) return chosen.languageCode;
    final device = _deviceLocale().languageCode;
    return supportedCodes.contains(device) ? device : 'en';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _preference = LanguagePreference.values.firstWhere(
      (p) => p.name == saved,
      orElse: () => LanguagePreference.system,
    );
  }

  Future<void> setPreference(LanguagePreference preference) async {
    if (preference == _preference) return;
    _preference = preference;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, preference.name);
  }
}
