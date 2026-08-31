import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_math.dart';

const tau = 2 * math.pi;
double deg(double d) => d * math.pi / 180;

void main() {
  test('lerpD interpola linealmente y clava los extremos', () {
    expect(lerpD(10, 20, 0), equals(10));
    expect(lerpD(10, 20, 1), equals(20));
    expect(lerpD(10, 20, 0.5), equals(15));
  });

  test('lerpAngle toma el camino corto de 350 a 10 grados', () {
    final mid = lerpAngle(deg(350), deg(10), 0.5) % tau;
    // El punto medio por el camino corto es 0 grados (o tau, equivalente).
    final dist = math.min(mid, tau - mid);
    expect(dist, lessThan(deg(0.001)));
  });

  test('lerpAngle toma el camino corto de 10 a 350 grados', () {
    final mid = lerpAngle(deg(10), deg(350), 0.5) % tau;
    final dist = math.min(mid, tau - mid);
    expect(dist, lessThan(deg(0.001)));
  });

  test('lerpAngle con t=0 y t=1 devuelve angulos equivalentes a los extremos', () {
    expect(lerpAngle(deg(350), deg(10), 0) % tau, closeTo(deg(350), 1e-9));
    expect(lerpAngle(deg(350), deg(10), 1) % tau, closeTo(deg(10), 1e-9));
  });

  test('easeOutQuint arranca en 0, acaba en 1 y va por delante de la recta', () {
    expect(easeOutQuint(0), closeTo(0, 1e-9));
    expect(easeOutQuint(1), closeTo(1, 1e-9));
    expect(easeOutQuint(0.5), greaterThan(0.5));
  });

  test('clamp01 recorta fuera de rango', () {
    expect(clamp01(-3), equals(0));
    expect(clamp01(0.4), equals(0.4));
    expect(clamp01(9), equals(1));
  });

  test('blendRadii clava los extremos e interpola cada indice', () {
    final a = [1.0, 2.0, 3.0];
    final b = [3.0, 2.0, 1.0];
    expect(blendRadii(a, b, 0), equals(a));
    expect(blendRadii(a, b, 1), equals(b));
    expect(blendRadii(a, b, 0.5), equals([2.0, 2.0, 2.0]));
  });

  test('blendRadii revienta si las longitudes no coinciden', () {
    expect(() => blendRadii([1.0], [1.0, 2.0], 0.5), throwsArgumentError);
  });
}
