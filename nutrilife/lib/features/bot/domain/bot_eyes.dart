//
// Portado de face.ts de Bloub (https://github.com/jeremy-prt/bloub)
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;

import 'bot_frame.dart';

const double kEyeW = 0.186;
const double kEyeH = 0.412;
const double kEyeSplit = 15.46; // grados
const double kGazeYaw = 28.49;
const double kGazePitch = 28.62;
const double kGazeRoll = -13;

double _deg(double d) => d * math.pi / 180;

/// Gira `u` hacia `v` por `angle`. Devuelve los dos vectores girados.
List<List<double>> _spin(List<double> u, List<double> v, double angle) {
  final c = math.cos(angle), s = math.sin(angle);
  return [
    [u[0] * c + v[0] * s, u[1] * c + v[1] * s, u[2] * c + v[2] * s],
    [v[0] * c - u[0] * s, v[1] * c - u[1] * s, v[2] * c - u[2] * s],
  ];
}

List<EyeSpec> _computeRestEyes() {
  var f = <double>[0, 0, 1];
  var right = <double>[1, 0, 0];
  var down = <double>[0, 1, 0];

  var r = _spin(f, right, _deg(kGazeYaw));
  f = r[0];
  right = r[1];

  r = _spin(down, f, _deg(kGazePitch));
  down = r[0];
  f = r[1];

  r = _spin(right, down, _deg(kGazeRoll));
  right = r[0];
  down = r[1];

  EyeSpec build(double side) {
    final e = _spin(f, right, _deg(kEyeSplit * side));
    final ef = e[0], er = e[1];
    return EyeSpec(
      cx: ef[0],
      cy: ef[1],
      rx: kEyeW / 2,
      ry: kEyeH / 2,
      a: er[0],
      b: er[1],
      c: down[0],
      d: down[1],
    );
  }

  return List<EyeSpec>.unmodifiable([build(-1), build(1)]);
}

/// Las dos poses de ojo en reposo. Constantes: en los cinco estados portados
/// la mirada nunca cambia, asi que no hace falta recalcularlas por frame.
final List<EyeSpec> kRestEyes = _computeRestEyes();
