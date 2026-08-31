//
// Matematica portada de Bloub (https://github.com/jeremy-prt/bloub) — MIT,
// (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;

const double tau = 2 * math.pi;

double lerpD(double a, double b, double t) => a + (b - a) * t;

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double easeOutQuint(double t) {
  final u = 1 - clamp01(t);
  return 1 - u * u * u * u * u;
}

/// Interpola angulos por el camino corto: de 350 a 10 grados pasa por 0,
/// no da la vuelta de 340 grados.
double lerpAngle(double a, double b, double t) {
  // En Dart, x % tau siempre cae en [0, tau) aunque x sea negativo.
  var d = (b - a) % tau;
  if (d > math.pi) d -= tau; // ahora en (-pi, pi]
  return a + d * t;
}

List<double> blendRadii(List<double> a, List<double> b, double t) {
  if (a.length != b.length) {
    throw ArgumentError('perfiles de distinta longitud: ${a.length} vs ${b.length}');
  }
  return List<double>.generate(a.length, (i) => lerpD(a[i], b[i], t), growable: false);
}
