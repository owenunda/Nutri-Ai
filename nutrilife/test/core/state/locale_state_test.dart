import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocaleState _state(String device) =>
    LocaleState(deviceLocale: () => Locale(device));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('por defecto sigue al teléfono', () async {
    final s = _state('en');
    await s.load();
    expect(s.preference, LanguagePreference.system);
    expect(s.locale, isNull);
    expect(s.languageCode, 'en');
  });

  test('un teléfono en otro idioma cae a inglés', () async {
    final s = _state('fr');
    await s.load();
    expect(s.languageCode, 'en');
  });

  test('guardar la preferencia la aplica y la recuerda', () async {
    final s = _state('es');
    await s.load();
    var avisos = 0;
    s.addListener(() => avisos++);

    await s.setPreference(LanguagePreference.en);

    expect(s.locale, const Locale('en'));
    expect(s.languageCode, 'en');
    expect(avisos, 1);

    final otra = _state('es');
    await otra.load();
    expect(otra.preference, LanguagePreference.en);
  });

  test('un valor guardado desconocido vuelve a sistema', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'klingon'});
    final s = _state('es');
    await s.load();
    expect(s.preference, LanguagePreference.system);
  });

  test('volver a sistema sigue otra vez al teléfono', () async {
    final s = _state('en');
    await s.load();
    await s.setPreference(LanguagePreference.es);
    expect(s.languageCode, 'es');

    await s.setPreference(LanguagePreference.system);

    expect(s.locale, isNull);
    expect(s.languageCode, 'en');
    final otra = _state('en');
    await otra.load();
    expect(otra.preference, LanguagePreference.system);
  });

  test('elegir el mismo idioma no avisa a nadie', () async {
    final s = _state('es');
    await s.load();
    await s.setPreference(LanguagePreference.en);
    var avisos = 0;
    s.addListener(() => avisos++);

    await s.setPreference(LanguagePreference.en);

    expect(avisos, 0);
  });
}
