import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_eyes.dart';

void main() {
  test('hay exactamente dos ojos', () {
    expect(kRestEyes.length, equals(2));
  });

  test('los dos ojos estan dentro de la bola', () {
    for (final e in kRestEyes) {
      final d = e.cx * e.cx + e.cy * e.cy;
      expect(d, lessThan(1.0), reason: 'ojo fuera de la esfera unidad');
    }
  });

  test('los ojos estan separados horizontalmente', () {
    expect((kRestEyes[0].cx - kRestEyes[1].cx).abs(), greaterThan(0.15));
  });

  test('la matriz de cada ojo no es degenerada', () {
    for (final e in kRestEyes) {
      final det = e.a * e.d - e.c * e.b;
      expect(det.abs(), greaterThan(0.01), reason: 'matriz degenerada: el ojo colapsa');
    }
  });

  test('las dimensiones son las medidas de Bloub', () {
    for (final e in kRestEyes) {
      expect(e.rx, closeTo(0.186 / 2, 1e-9));
      expect(e.ry, closeTo(0.412 / 2, 1e-9));
    }
  });
}
