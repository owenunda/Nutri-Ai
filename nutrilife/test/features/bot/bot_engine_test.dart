import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/bot/domain/bot_engine.dart';
import 'package:nutrilife/features/bot/domain/bot_eyes.dart';
import 'package:nutrilife/features/bot/domain/bot_mood.dart';

void main() {
  test('arranca en idle y asentado', () {
    final e = BotEngine();
    expect(e.effectiveMood, equals(BotMood.idle));
    expect(e.isSettled, isTrue);
  });

  test('sample es determinista para el mismo t', () {
    final e = BotEngine();
    expect(e.sample(1.234), equals(e.sample(1.234)));
  });

  test('sample devuelve kProfileSamples radios', () {
    final e = BotEngine();
    expect(e.sample(0).radii.length, equals(64));
  });

  test('idle muestra el cuerpo y dos ojos, sin puntos', () {
    final e = BotEngine();
    final f = e.sample(2.0);
    expect(f.bodyAlpha, greaterThan(0.95));
    expect(f.eyes.length, equals(2));
    expect(f.dots, isEmpty);
  });

  test('el parpadeo abre-cierra-abre dentro de la ventana, y fuera esta abierto', () {
    final e = BotEngine();
    // Espejo de las constantes privadas de BotEngine._lid: periodo 3.25s y
    // ventana de parpadeo BLINK_DUR=0.18s (face.ts:121,131).
    const blinkDur = 0.18;
    const periodo = 3.25;

    final abiertoInicio = e.sample(0.0).eyes[0].ry;
    final cerrado = e.sample(blinkDur / 2).eyes[0].ry;
    final abiertoFin = e.sample(blinkDur * 0.999).eyes[0].ry;
    final fueraDeLaVentana = e.sample(periodo / 2).eyes[0].ry;

    expect(cerrado, lessThan(abiertoInicio),
        reason: 'el ojo deberia cerrarse hacia el centro de la ventana de parpadeo');
    expect(cerrado, lessThan(abiertoFin),
        reason: 'el ojo deberia reabrirse hacia el final de la ventana de parpadeo');
    expect(fueraDeLaVentana, closeTo(kRestEyes[0].ry, 1e-9),
        reason: 'fuera de la ventana de parpadeo el ojo tiene que estar totalmente abierto');
  });

  test('thinking oculta el cuerpo y muestra tres puntos', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    expect(f.bodyAlpha, lessThan(0.05));
    expect(f.dots.length, equals(3));
    expect(f.eyes, isEmpty);
  });

  test('los tres puntos estan en las posiciones medidas de Bloub', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    expect(f.dots[0].cx, closeTo(-0.557, 1e-9));
    expect(f.dots[1].cx, closeTo(-0.013, 1e-9));
    expect(f.dots[2].cx, closeTo(0.532, 1e-9));
  });

  test('los puntos pulsan desfasados 0.5s entre si (formula dotPulse, states.ts:200)', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(0.15);
    // Valores calculados independientemente de dotPulse(0.15, i) con
    // r = DOT_R * (1 + (DOT_PEAK - 1) * pulso) y alpha = lerp(0.55, 1.0, pulso).
    // Un desfase equivocado (p.ej. index*0.25 en vez de index*0.5) daria
    // otros numeros aqui, no solo "menos radios distintos".
    expect(f.dots[0].r, closeTo(0.172878, 1e-6));
    expect(f.dots[0].alpha, closeTo(0.635942, 1e-6));
    expect(f.dots[1].r, closeTo(0.165, 1e-6));
    expect(f.dots[1].alpha, closeTo(0.55, 1e-6));
    expect(f.dots[2].r, closeTo(0.20625, 1e-6));
    expect(f.dots[2].alpha, closeTo(1.0, 1e-6));
  });

  test('sleeping encoge la bola y la hace rebotar', () {
    final e = BotEngine()..hold(BotMood.sleeping);
    final a = e.sample(2.0);
    final b = e.sample(2.3);
    expect(a.sx, closeTo(0.1585, 1e-9));
    expect(a.cy, isNot(closeTo(b.cy, 1e-6)), reason: 'no rebota');
  });

  test('sleeping no dibuja ojos (states.ts:372, eyeAlpha 0)', () {
    final e = BotEngine()..hold(BotMood.sleeping);
    expect(e.sample(2.0).eyes, isEmpty);
  });

  test('PRECEDENCIA: sleeping gana sobre thinking', () {
    final e = BotEngine()
      ..hold(BotMood.thinking)
      ..hold(BotMood.sleeping);
    expect(e.effectiveMood, equals(BotMood.sleeping));
  });

  test('PRECEDENCIA: un pulse durante thinking no interrumpe el pensar', () {
    final e = BotEngine()..hold(BotMood.thinking);
    e.pulse(BotMood.pleased);
    expect(e.effectiveMood, equals(BotMood.thinking));
  });

  test('un pulse sobre idle si se aplica', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    expect(e.effectiveMood, equals(BotMood.pleased));
    expect(e.isSettled, isFalse);
  });

  test('un pulse termina solo y vuelve a idle', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    e.sample(5.0);
    expect(e.effectiveMood, equals(BotMood.idle));
    expect(e.isSettled, isTrue);
  });

  test('pleased cierra un ojo y deja el otro abierto', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    final f = e.sample(0.45); // mitad del pulse
    expect(f.eyes[1].ry, lessThan(f.eyes[0].ry * 0.5));
  });

  test('fpsFor declara cadencia reducida en idle y plena en thinking', () {
    expect(BotEngine.fpsFor(BotMood.idle), equals(15));
    expect(BotEngine.fpsFor(BotMood.thinking), equals(60));
    expect(BotEngine.fpsFor(BotMood.pleased), equals(60));
    expect(BotEngine.fpsFor(BotMood.sleeping), equals(30));
  });

  // --- Gaze tracking -----------------------------------------------------

  test('sin setGaze, los ojos estan en su posicion de reposo', () {
    final e = BotEngine();
    final f = e.sample(1.0);
    expect(f.eyes[0].gazeDx, equals(0));
    expect(f.eyes[0].gazeDy, equals(0));
    expect(f.eyes[1].gazeDx, equals(0));
    expect(f.eyes[1].gazeDy, equals(0));
  });

  test('setGaze desplaza ambos ojos en la misma direccion', () {
    final e = BotEngine()..setGaze(0.2, 0.1);
    final f = e.sample(10.0); // dt grande -> converge al target
    expect(f.eyes[0].gazeDx, closeTo(0.2, 1e-9));
    expect(f.eyes[0].gazeDy, closeTo(0.1, 1e-9));
    expect(f.eyes[1].gazeDx, closeTo(0.2, 1e-9));
    expect(f.eyes[1].gazeDy, closeTo(0.1, 1e-9));
  });

  test('setGaze clamp-a magnitud para que el ojo no salga de la esfera', () {
    final e = BotEngine()..setGaze(1.0, 1.0); // magnitud sqrt(2) >> 0.40
    final f = e.sample(10.0);
    final m = math.sqrt(f.eyes[0].gazeDx * f.eyes[0].gazeDx +
        f.eyes[0].gazeDy * f.eyes[0].gazeDy);
    expect(m, closeTo(0.40, 1e-9));
    // La direccion se conserva: dx == dy.
    expect((f.eyes[0].gazeDx - f.eyes[0].gazeDy).abs(), lessThan(1e-9));
  });

  test('el gaze se suaviza: el primer sample tras setGaze esta entre 0 y target', () {
    final e = BotEngine()..setGaze(0.2, 0);
    final f = e.sample(0.05); // dt = 0.05, smoothing k ~ 1-exp(-8*0.05) = 0.33
    expect(f.eyes[0].gazeDx, greaterThan(0));
    expect(f.eyes[0].gazeDx, lessThan(0.2));
    expect(f.eyes[0].gazeDx, closeTo(0.2 * (1 - math.exp(-0.4)), 1e-6));
  });

  test('samples sucesivos convergen monotamente al target', () {
    final e = BotEngine()..setGaze(0.2, 0);
    final f1 = e.sample(0.05);
    final f2 = e.sample(0.20);
    final f3 = e.sample(3.0);
    expect(f1.eyes[0].gazeDx, lessThan(f2.eyes[0].gazeDx));
    expect(f2.eyes[0].gazeDx, lessThan(f3.eyes[0].gazeDx));
    // A t=3.0 con k=6 la convergencia es 1-exp(-18) ≈ 1.0 -> ~0.2.
    expect(f3.eyes[0].gazeDx, closeTo(0.2, 1e-6));
  });

  test('el parpadeo y el gaze coexisten (gaze no afecta ry)', () {
    final e = BotEngine()..setGaze(0.2, 0);
    final f = e.sample(10.0); // gaze ya convergido
    final ojoEnMira = f.eyes[0];
    // Fuera de la ventana de blink el ojo esta totalmente abierto.
    expect(ojoEnMira.ry, closeTo(kRestEyes[0].ry, 1e-9));
    expect(ojoEnMira.gazeDx, closeTo(0.2, 1e-9));
  });

  test('reloj no monotono (tests que rebobinan) no rompe el gaze', () {
    final e = BotEngine()..setGaze(0.2, 0);
    e.sample(10.0); // converge
    final antes = e.sample(5.0); // dt < 0 -> se trata como 0, no retrocede
    expect(antes.eyes[0].gazeDx, closeTo(0.2, 1e-9));
  });
}
