import 'package:flutter/material.dart';

/// Vaso del reto de agua según los vasos de hoy. Cada nivel es una sola
/// imagen que ya trae su propia nutria.
class WaterProgressIllustration extends StatelessWidget {
  const WaterProgressIllustration({
    super.key,
    required this.glasses,
    required this.height,
  });

  final int glasses;
  final double height;

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Image.asset(
          _assetPath,
          key: ValueKey(_assetPath),
          cacheWidth: 800,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
