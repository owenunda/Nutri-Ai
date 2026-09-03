import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_frame.dart';
import 'package:nutriapp/features/bot/presentation/bot_path.dart';

BotFrame circulo({double sx = 1, double sy = 1, double cx = 0, double cy = 0}) => BotFrame(
      radii: List<double>.filled(64, 1.0),
      rot: 0,
      cx: cx,
      cy: cy,
      sx: sx,
      sy: sy,
      bodyAlpha: 1,
      eyes: const [],
      dots: const [],
    );

void main() {
  const size = Size(100, 100);

  test('un perfil de radios constantes cae sobre un circulo centrado', () {
    final pts = profilePoints(circulo(), size);
    expect(pts.length, equals(64));
    for (final p in pts) {
      final d = (p - const Offset(50, 50)).distance;
      expect(d, closeTo(50, 0.001));
    }
  });

  test('cx desplaza el centro en unidades de radio', () {
    final pts = profilePoints(circulo(cx: 0.5), size);
    final centro = pts.reduce((a, b) => a + b) / 64.0;
    expect(centro.dx, closeTo(50 + 25, 0.5));
    expect(centro.dy, closeTo(50, 0.5));
  });

  test('sy aplasta verticalmente', () {
    final pts = profilePoints(circulo(sy: 0.5), size);
    final maxY = pts.map((p) => p.dy).reduce(math.max);
    expect(maxY - 50, closeTo(25, 0.001));
  });

  test('el path cerrado sobre un circulo tiene un bounding box del tamano esperado', () {
    final path = closedCatmullRomPath(profilePoints(circulo(), size));
    final b = path.getBounds();
    expect(b.width, closeTo(100, 1.0));
    expect(b.height, closeTo(100, 1.0));
  });

  test('el path contiene el centro y excluye una esquina', () {
    final path = closedCatmullRomPath(profilePoints(circulo(), size));
    expect(path.contains(const Offset(50, 50)), isTrue);
    expect(path.contains(const Offset(2, 2)), isFalse);
  });

  test('catmullRomControls da los valores exactos para un segmento asimetrico', () {
    // p0=(0,0), p1=(1,0), p2=(2,1), p3=(3,0)
    // c1 = p1 + (p2-p0)/6 = (1,0) + (2,1)/6      = (1.3333333, 0.1666667)
    // c2 = p2 - (p3-p1)/6 = (2,1) - (2,0)/6      = (1.6666667, 1.0)
    // Valores calculados a mano desde la formula, no desde el codigo.
    const p0 = Offset(0, 0);
    const p1 = Offset(1, 0);
    const p2 = Offset(2, 1);
    const p3 = Offset(3, 0);

    final controls = catmullRomControls(p0, p1, p2, p3);

    expect(controls.c1.dx, closeTo(1.3333333, 1e-6));
    expect(controls.c1.dy, closeTo(0.1666667, 1e-6));
    expect(controls.c2.dx, closeTo(1.6666667, 1e-6));
    expect(controls.c2.dy, closeTo(1.0, 1e-6));
  });
}
