import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'ads_service.dart';

// Banner adaptativo a lo ancho de la pantalla. Mientras no haya anuncio
// cargado (o el usuario sea Premium) no ocupa espacio.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int? _loadedWidth;

  @override
  void initState() {
    super.initState();
    AdsService.instance.canShowAds.addListener(_onAvailabilityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void dispose() {
    AdsService.instance.canShowAds.removeListener(_onAvailabilityChanged);
    _ad?.dispose();
    super.dispose();
  }

  void _onAvailabilityChanged() {
    if (AdsService.instance.canShowAds.value) {
      _load();
    } else {
      _clear();
    }
  }

  void _clear() {
    _ad?.dispose();
    if (!mounted) return;
    setState(() {
      _ad = null;
      _loaded = false;
      _loadedWidth = null;
    });
  }

  Future<void> _load() async {
    if (!AdsService.instance.canShowAds.value || _loading) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    // Al rotar cambia el ancho: el banner se pide de nuevo a la medida.
    if (_ad != null && _loadedWidth == width) return;
    _loading = true;

    // El adaptativo normal (~50-56 dp) y no el "large" (~64 dp), que le
    // quitaba demasiado espacio a las listas. Google lo marca deprecado en
    // favor del large, pero sigue funcionando.
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      _loading = false;
      return;
    }

    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: AdsConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[ads] banner no cargó: ${error.message}');
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
            _loadedWidth = null;
          });
        },
      ),
    );
    _loadedWidth = width;
    _loaded = false;
    _loading = false;
    await _ad!.load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
