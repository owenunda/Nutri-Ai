import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

class WaterProgressIllustration extends StatelessWidget {
  const WaterProgressIllustration({
    super.key,
    required this.glasses,
    required this.height,
    this.showDrinkingOtter = false,
  });

  final int glasses;
  final double height;
  final bool showDrinkingOtter;

  String get _assetPath {
    final stage = switch (glasses) {
      <= 0 => '01_vacio',
      1 => '02_25',
      2 => '03_50',
      3 => '04_75',
      _ => '05_meta_cumplida',
    };
    return 'assets/images/hydration/hidratacion_$stage.png';
  }

  Widget _cupAndDrinkingOtter(BuildContext context) {
    return Row(
      key: ValueKey('$_assetPath-drinking-otter'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 0.54,
            child: Image.asset(
              _assetPath,
              height: height,
              fit: BoxFit.fitHeight,
              cacheWidth: 800,
            ),
          ),
        ),
        Image.asset(
          'assets/images/nutria tomando agua.png',
          width: height * 0.46,
          height: height * 0.62,
          fit: BoxFit.contain,
          semanticLabel: context.l10n.hydrationDrinkingOtter,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: showDrinkingOtter
            ? _cupAndDrinkingOtter(context)
            : Image.asset(
                _assetPath,
                key: ValueKey(_assetPath),
                cacheWidth: 800,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
