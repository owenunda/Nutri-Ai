import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/bot/domain/bot_frame.dart';
import 'package:nutrilife/features/bot/domain/bot_mood.dart';
import 'package:nutrilife/features/bot/presentation/bot_avatar.dart';
import 'package:nutrilife/features/bot/presentation/bot_painter.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

BotPainter _painterActual(WidgetTester tester) {
  final cp = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(BotAvatar), matching: find.byType(CustomPaint)).last,
  );
  return cp.painter! as BotPainter;
}

/// Bombea en pasos pequeños durante ~1s de tiempo simulado y cuenta cuantas
/// veces el `BotFrame` pintado cambia respecto al paso anterior. Sirve para
/// medir la cadencia real (fps efectivos) que `_onTick` deja pasar para cada
/// mood, no solo que el frame avance en algun momento.
///
/// El paso es de 5ms (no 16ms) a proposito: con pasos de 16ms el intervalo de
/// 60fps (16.667ms) entra casi en fase con el paso del pump y casi la mitad
/// de los ticks quedan descartados por "doble paso" (aliasing), lo que hunde
/// el conteo de `thinking` muy por debajo de lo que 60fps deberia dar. Con
/// 5ms el paso queda bien por debajo de cualquier intervalo de fps en juego
/// (66.7ms para 15fps, 16.7ms para 60fps) y el conteo deja de depender de
/// como caiga el redondeo.
Future<int> _contarFramesDistintos(WidgetTester tester, BotMood mood) async {
  await tester.pumpWidget(_app(BotAvatar(mood: mood)));
  BotFrame? anterior;
  var cambios = 0;
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 5));
    final f = _painterActual(tester).frame;
    if (anterior != null && f != anterior) cambios++;
    anterior = f;
  }
  return cambios;
}

void main() {
  testWidgets('se monta y pinta con un BotPainter', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle)));
    expect(find.byType(BotAvatar), findsOneWidget);
    expect(_painterActual(tester), isA<BotPainter>());
  });

  testWidgets('el frame avanza con el tiempo', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    final antes = _painterActual(tester).frame;
    await tester.pump(const Duration(milliseconds: 300));
    expect(_painterActual(tester).frame, isNot(equals(antes)));
  });

  testWidgets('cambiar el mood por parametro llega al motor', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painterActual(tester).frame.dots, isEmpty);

    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painterActual(tester).frame.dots.length, equals(3));
  });

  testWidgets('respeta el tamano pedido', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle, size: 32)));
    final box = tester.getSize(find.byType(BotAvatar));
    expect(box.width, equals(32));
    expect(box.height, equals(32));
  });

  testWidgets('la cadencia descarta frames segun el mood (idle 15fps vs thinking 60fps)',
      (tester) async {
    final cambiosIdle = await _contarFramesDistintos(tester, BotMood.idle);
    final cambiosThinking = await _contarFramesDistintos(tester, BotMood.thinking);

    // Umbrales con holgura: el reparto exacto depende de como caiga el
    // redondeo del intervalo, pero la diferencia entre 15fps y 60fps sobre
    // ~1s de tiempo simulado (200 pasos de 5ms) tiene que ser clara. Medido:
    // idle ~12-14 cambios, thinking ~37-39 cambios.
    expect(cambiosIdle, lessThan(20));
    expect(cambiosThinking, greaterThan(30));
    expect(cambiosIdle, lessThan(cambiosThinking));
  });

  testWidgets('se desmonta sin dejar el ticker vivo', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    // Si el ticker sobreviviera al dispose, flutter_test falla el test
    // automaticamente al terminar con "A Ticker was active when disposed".
    expect(find.byType(BotAvatar), findsNothing);
  });
}
