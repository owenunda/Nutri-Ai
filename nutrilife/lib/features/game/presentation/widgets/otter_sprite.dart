import 'package:flutter/material.dart';

/// Un cuadro de un spritesheet de la nutria: 6 cuadros cuadrados en una fila,
/// de izquierda a derecha (ver nutrilifeGame/.../README.md).
class OtterSprite extends StatelessWidget {
  const OtterSprite({
    super.key,
    required this.sheet,
    required this.frame,
    required this.size,
  });

  static const frameCount = 6;

  final String sheet;
  final int frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      // Con cover la hoja se escala a la altura de la caja y la alineación
      // elige qué franja de ancho se ve: -1 el primer cuadro, 1 el último.
      child: Image.asset(
        sheet,
        fit: BoxFit.cover,
        alignment: Alignment(-1 + 2 * frame / (frameCount - 1), 0),
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      ),
    );
  }
}
