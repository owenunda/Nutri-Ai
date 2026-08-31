// Conversion de perfiles radiales a Path. La tecnica (Catmull-Rom sobre
// muestras radiales) viene de Bloub — https://github.com/jeremy-prt/bloub
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;
import 'dart:ui';

import '../domain/bot_frame.dart';

/// Convierte los radios normalizados del frame en puntos de pantalla.
List<Offset> profilePoints(BotFrame f, Size size) {
  final n = f.radii.length;
  final r0 = size.shortestSide / 2;
  final ox = size.width / 2 + f.cx * r0;
  final oy = size.height / 2 + f.cy * r0;
  return List<Offset>.generate(n, (i) {
    final a = (i / n) * 2 * math.pi + f.rot;
    return Offset(
      ox + math.cos(a) * f.radii[i] * r0 * f.sx,
      oy + math.sin(a) * f.radii[i] * r0 * f.sy,
    );
  }, growable: false);
}

/// Spline Catmull-Rom cerrada, convertida a Bezier cubica.
///
/// Para cada segmento P1->P2, los puntos de control salen de los vecinos:
///   c1 = P1 + (P2 - P0) / 6
///   c2 = P2 - (P3 - P1) / 6
Path closedCatmullRomPath(List<Offset> pts) {
  final n = pts.length;
  final path = Path();
  if (n < 4) return path;

  path.moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}
