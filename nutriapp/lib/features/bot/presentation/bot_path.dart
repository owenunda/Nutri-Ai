// Conversion de perfiles radiales a Path. La tecnica (Catmull-Rom sobre
// muestras radiales) viene de Bloub — https://github.com/jeremy-prt/bloub
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;
import 'dart:ui';

import '../domain/bot_frame.dart';

/// Radio de la bola en reposo, como fraccion del medio-lienzo (no 1.0).
///
/// Bloub (`bot/repere.ts`) usa `RAYON=100` sobre `DEMI_VIEWBOX=158`: deja
/// ~58% de margen porque tiene estados como `orbit`/`comet` que llegan a
/// 1.4x el radio de reposo. No portamos esos estados, asi que copiar ese
/// margen encogeria el blob a un 63% sin necesidad. Seguimos el mismo
/// principio (inscribir la bola con margen, no a ras del lienzo) pero
/// ajustado a nuestro alcance real: la unica excursion por encima de 1.0
/// es `surprised` a 1.06, asi que basta con medio-lienzo = 1.15 radios.
const double kRestBallFraction = 1 / 1.15;

/// Radio en pixeles de la bola en reposo para un lienzo dado. El painter y
/// `profilePoints` DEBEN usar esta misma funcion — si uno calcula su propio
/// `shortestSide / 2`, el cuerpo y los ojos/puntos quedan a escalas
/// distintas y se despegan entre si.
double ballRadius(Size size) => size.shortestSide / 2 * kRestBallFraction;

/// Convierte los radios normalizados del frame en puntos de pantalla.
List<Offset> profilePoints(BotFrame f, Size size) {
  final n = f.radii.length;
  final r0 = ballRadius(size);
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

/// Puntos de control Bezier de un segmento Catmull-Rom p1->p2.
///
/// La tension 1/6 es la de Bloub (shape.ts:103).
///   c1 = P1 + (P2 - P0) / 6
///   c2 = P2 - (P3 - P1) / 6
({Offset c1, Offset c2}) catmullRomControls(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
) {
  return (c1: p1 + (p2 - p0) / 6, c2: p2 - (p3 - p1) / 6);
}

/// Spline Catmull-Rom cerrada, convertida a Bezier cubica.
///
/// Para cada segmento P1->P2, los puntos de control salen de los vecinos
/// (ver [catmullRomControls]).
Path closedCatmullRomPath(List<Offset> pts) {
  final n = pts.length;
  final path = Path();
  // Bloub exige n >= 3 (shape.ts:103); aqui pedimos n >= 4 porque con 4
  // puntos la ventana de vecinos p0..p3 ya esta bien definida sin
  // duplicados. En la practica `radii` siempre trae 64 muestras.
  if (n < 4) return path;

  path.moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final controls = catmullRomControls(p0, p1, p2, p3);
    path.cubicTo(
      controls.c1.dx,
      controls.c1.dy,
      controls.c2.dx,
      controls.c2.dy,
      p2.dx,
      p2.dy,
    );
  }
  path.close();
  return path;
}
