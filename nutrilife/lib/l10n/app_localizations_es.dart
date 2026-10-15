// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NutriLife';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonErrorTimeout =>
      'La conexión con el servidor tardó demasiado. Inténtalo de nuevo.';

  @override
  String get commonErrorConnection =>
      'No se pudo conectar con el servidor. Revisa tu conexión a internet.';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileLanguageSystem => 'Usar el del teléfono';

  @override
  String get profileLanguageSheetTitle => 'Elige el idioma';
}
