import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/bot/presentation/bot_avatar.dart';
import 'package:nutriapp/features/bot/presentation/bot_painter.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

BotPainter _painterActual(WidgetTester tester) {
  final cp = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(BotAvatar), matching: find.byType(CustomPaint)).last,
  );
  return cp.painter! as BotPainter;
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
