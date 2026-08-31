import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_engine.dart';
import 'package:nutriapp/features/bot/domain/bot_eyes.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

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

  test('idle parpadea en algun momento de los primeros 10 segundos', () {
    final e = BotEngine();
    var vioCerrado = false;
    for (var i = 0; i < 1000; i++) {
      final f = e.sample(i * 0.01);
      if (f.eyes.isNotEmpty && f.eyes[0].ry < kRestEyes[0].ry * 0.5) {
        vioCerrado = true;
        break;
      }
    }
    expect(vioCerrado, isTrue, reason: 'no parpadeo nunca');
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

  test('los puntos pulsan desfasados: no todos tienen el mismo radio', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    final radios = f.dots.map((d) => d.r).toSet();
    expect(radios.length, greaterThan(1));
  });

  test('sleeping encoge la bola y la hace rebotar', () {
    final e = BotEngine()..hold(BotMood.sleeping);
    final a = e.sample(2.0);
    final b = e.sample(2.3);
    expect(a.sx, closeTo(0.1585, 1e-9));
    expect(a.cy, isNot(closeTo(b.cy, 1e-6)), reason: 'no rebota');
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
}
