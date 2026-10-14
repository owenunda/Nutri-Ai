import 'dart:io';

import 'package:flutter/foundation.dart';

// IDs de bloques de anuncios de AdMob.
//
// Cuando tengas la cuenta de AdMob, pega aquí los IDs reales de cada bloque
// (ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN). Los App IDs (con "~") NO van
// aquí: van en android/app/src/main/AndroidManifest.xml y en
// ios/Runner/Info.plist.
//
// Mientras estén vacíos, y siempre en debug, se usan los IDs de prueba de
// Google: muestran anuncios de ejemplo y no cuentan como clics reales.
// Probar con IDs reales puede hacer que AdMob suspenda la cuenta.
class AdsConfig {
  const AdsConfig._();

  static const _androidBanner = 'ca-app-pub-8768785455820831/8554349182';
  static const _androidInterstitial = 'ca-app-pub-8768785455820831/2734301431';
  // iOS va con los de prueba hasta que exista la app iOS en AdMob y su App ID
  // esté en Info.plist: bloques reales con el App ID de prueba no sirven
  // anuncios. Bloques ya creados para entonces:
  //   banner ca-app-pub-8768785455820831/7010167371
  //   intersticial ca-app-pub-8768785455820831/4384004033
  static const _iosBanner = '';
  static const _iosInterstitial = '';

  // https://developers.google.com/admob/flutter/test-ads
  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  // El SDK solo existe en Android e iOS (no en web ni escritorio, ni en tests).
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerUnitId => Platform.isIOS
      ? _pick(_iosBanner, _testIosBanner)
      : _pick(_androidBanner, _testAndroidBanner);

  static String get interstitialUnitId => Platform.isIOS
      ? _pick(_iosInterstitial, _testIosInterstitial)
      : _pick(_androidInterstitial, _testAndroidInterstitial);

  static String _pick(String real, String test) =>
      kReleaseMode && real.isNotEmpty ? real : test;
}
