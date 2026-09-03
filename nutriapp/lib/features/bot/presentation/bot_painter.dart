// Painter del blob: cuerpo (Catmull-Rom cerrado), ojos con repere tangente
// a la esfera y puntos de "thinking". Tecnica y constantes portadas de Bloub
// (https://github.com/jeremy-prt/bloub) — MIT, (c) jeremy-prt.
// Ver THIRD_PARTY_NOTICES.md.
import 'dart:typed_data';

import 'package:flutter/rendering.dart';

import '../domain/bot_frame.dart';
import 'bot_path.dart';

class BotPainter extends CustomPainter {
  final BotFrame frame;
  final Color bodyColor;
  final Color eyeColor;

  const BotPainter({
    required this.frame,
    required this.bodyColor,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r0 = size.shortestSide / 2;
    final ox = size.width / 2;
    final oy = size.height / 2;

    if (frame.bodyAlpha > 0.001) {
      final cuerpo = closedCatmullRomPath(profilePoints(frame, size));
      canvas.drawPath(
        cuerpo,
        Paint()
          ..color = bodyColor.withValues(alpha: frame.bodyAlpha)
          ..isAntiAlias = true,
      );
    }

    for (final e in frame.eyes) {
      if (e.alpha <= 0.001 || e.ry <= 0.001) continue;
      // El ojo NO se dibuja alineado al eje: `EyeSpec` trae una matriz 2x2
      // (a,b,c,d) con el repere tangente a la esfera, y es lo que da el
      // escorzo. Dibujar un RRect recto tiraria esa informacion.
      // Matrix4.storage es column-major: [col*4 + row].
      final m = Float64List(16)
        ..[0] = e.a // m00
        ..[1] = e.b // m10
        ..[4] = e.c // m01
        ..[5] = e.d // m11
        ..[10] = 1
        ..[15] = 1;
      canvas.save();
      canvas.translate(ox + e.cx * r0, oy + e.cy * r0);
      canvas.transform(m);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: e.rx * 2 * r0,
        height: e.ry * 2 * r0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(e.rx * r0)),
        Paint()..color = eyeColor.withValues(alpha: e.alpha),
      );
      canvas.restore();
    }

    for (final d in frame.dots) {
      if (d.alpha <= 0.001) continue;
      canvas.drawCircle(
        Offset(ox + d.cx * r0, oy + d.cy * r0),
        d.r * r0,
        Paint()..color = bodyColor.withValues(alpha: d.alpha),
      );
    }
  }

  // `covariant` es obligatorio: CustomPainter declara shouldRepaint(CustomPainter),
  // y estrechar el tipo del parametro sin covariant es error de compilacion.
  @override
  bool shouldRepaint(covariant BotPainter old) =>
      old.frame != frame || old.bodyColor != bodyColor || old.eyeColor != eyeColor;
}
