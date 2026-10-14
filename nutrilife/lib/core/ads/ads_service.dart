import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'interstitial_policy.dart';

// Punto único de los anuncios: consentimiento, permiso de seguimiento en iOS,
// arranque del SDK, plan del usuario e intersticial. Ningún fallo de aquí
// debe romper la app: si algo sale mal, simplemente no hay anuncios.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  // true cuando el SDK está listo y el plan del usuario lleva anuncios.
  // El banner lo escucha para cargarse o desaparecer.
  final ValueNotifier<bool> canShowAds = ValueNotifier(false);

  final InterstitialPolicy _policy = InterstitialPolicy();
  bool _initStarted = false;
  bool _sdkReady = false;
  String? _plan;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  Future<void> init() async {
    if (!AdsConfig.isSupported || _initStarted) return;
    _initStarted = true;

    try {
      // El formulario de Google solo aparece donde la ley lo exige (UE,
      // Reino Unido, Suiza); en el resto vuelve sin mostrar nada.
      await _gatherConsent();
      if (Platform.isIOS) await _requestTrackingPermission();
      if (!await ConsentInformation.instance.canRequestAds()) return;

      await MobileAds.instance.initialize();
      _sdkReady = true;
      _refresh();
    } catch (error) {
      debugPrint('[ads] no se pudieron iniciar los anuncios: $error');
    }
  }

  // Premium no ve anuncios. Sin plan conocido se trata como FREE.
  void setPlan(String? plan) {
    _plan = plan;
    _refresh();
  }

  // Llamar después de registrar comida. Si toca anuncio, espera a que el
  // usuario lo cierre, para que lo que venga después (el aviso con
  // "Deshacer") no quede tapado.
  Future<void> maybeShowAfterMealLog() async {
    if (!canShowAds.value) return;
    if (!_policy.onMealLogged(DateTime.now())) return;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;

    final closed = Completer<void>();
    void finish(InterstitialAd ad) {
      ad.dispose();
      if (!closed.isCompleted) closed.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _policy.markShown(DateTime.now()),
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );

    try {
      await ad.show();
      await closed.future;
    } catch (error) {
      debugPrint('[ads] no se pudo mostrar el intersticial: $error');
    }
  }

  bool get _planAllowsAds => (_plan ?? 'FREE').toUpperCase() == 'FREE';

  void _refresh() {
    final allowed = _sdkReady && _planAllowsAds;
    canShowAds.value = allowed;

    if (allowed) {
      _loadInterstitial();
    } else {
      _interstitial?.dispose();
      _interstitial = null;
    }
  }

  void _loadInterstitial() {
    if (!canShowAds.value || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          if (canShowAds.value) {
            _interstitial = ad;
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('[ads] intersticial no cargó: ${error.message}');
        },
      ),
    );
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('[ads] consentimiento: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
        if (!done.isCompleted) done.complete();
      },
      (error) {
        debugPrint('[ads] consentimiento: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );

    return done.future;
  }

  Future<void> _requestTrackingPermission() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
