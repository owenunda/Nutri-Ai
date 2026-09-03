import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/bot/domain/bot_engine.dart';
import 'package:nutrilife/features/bot/domain/bot_mood.dart';
import 'package:nutrilife/features/bot/presentation/bot_painter.dart';

// Key propia: MaterialApp y Scaffold montan sus propios CustomPaint, asi que
// find.byType(CustomPaint).last no garantiza ser el nuestro.
const kBlobKey = ValueKey('blob-test');

Widget _caja(BotEngine e, double t) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A6B3F),
        body: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            // La key va en el RepaintBoundary, no en el CustomPaint: sin un
            // RenderRepaintBoundary propio aqui, matchesGoldenFile sube por
            // el arbol de render hasta encontrar uno (el de la superficie de
            // test, 800x600) y captura eso en vez del blob de 50x50.
            child: RepaintBoundary(
              key: kBlobKey,
              child: CustomPaint(
                painter: BotPainter(
                  frame: e.sample(t),
                  bodyColor: const Color(0xFFFFFFFF),
                  eyeColor: const Color(0xFF134E32),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shouldRepaint es false con el mismo frame', (tester) async {
    final e = BotEngine();
    final f = e.sample(1.0);
    const blanco = Color(0xFFFFFFFF);
    const verde = Color(0xFF134E32);
    final a = BotPainter(frame: f, bodyColor: blanco, eyeColor: verde);
    final b = BotPainter(frame: f, bodyColor: blanco, eyeColor: verde);
    expect(a.shouldRepaint(b), isFalse);
  });

  testWidgets('shouldRepaint es true con frames distintos', (tester) async {
    final e = BotEngine();
    const blanco = Color(0xFFFFFFFF);
    const verde = Color(0xFF134E32);
    final a = BotPainter(frame: e.sample(0.0), bodyColor: blanco, eyeColor: verde);
    final b = BotPainter(frame: e.sample(1.0), bodyColor: blanco, eyeColor: verde);
    expect(a.shouldRepaint(b), isTrue);
  });

  for (final caso in <String, BotMood>{
    'idle': BotMood.idle,
    'thinking': BotMood.thinking,
    'sleeping': BotMood.sleeping,
  }.entries) {
    testWidgets('golden ${caso.key}', (tester) async {
      final e = BotEngine()..hold(caso.value);
      await tester.pumpWidget(_caja(e, 2.0));
      await expectLater(
        find.byKey(kBlobKey),
        matchesGoldenFile('goldens/bot_${caso.key}.png'),
      );
    });
  }

  testWidgets('golden pleased', (tester) async {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    await tester.pumpWidget(_caja(e, 0.45)); // mitad del pulse: guino cerrado
    await expectLater(
      find.byKey(kBlobKey),
      matchesGoldenFile('goldens/bot_pleased.png'),
    );
  });

  testWidgets('golden surprised', (tester) async {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.surprised);
    await tester.pumpWidget(_caja(e, 0.45));
    await expectLater(
      find.byKey(kBlobKey),
      matchesGoldenFile('goldens/bot_surprised.png'),
    );
  });
}
