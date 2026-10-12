import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/bot_message_text.dart';

Future<void> _pump(WidgetTester tester, String text) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BotMessageText(text: text))),
    );

/// Junta el texto de todos los RichText, que es como pinta el markdown.
String _visibleText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((r) => r.text.toPlainText())
    .join('\n');

void main() {
  testWidgets('pinta las negritas sin mostrar los asteriscos', (tester) async {
    await _pump(tester, 'Necesitas **2 huevos** y sal');

    expect(_visibleText(tester), contains('2 huevos'));
    expect(_visibleText(tester), isNot(contains('**')));

    final bold = tester
        .widgetList<RichText>(find.byType(RichText))
        .expand((r) => _spans(r.text))
        .where((s) => s.text == '2 huevos');
    expect(bold.single.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('cada paso de una lista numerada va en su propia línea',
      (tester) async {
    await _pump(tester, 'Así se hace:\n\n1. Pela la banana\n2. Licúa todo');

    final lines = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .toList();
    expect(lines, contains('Pela la banana'));
    expect(lines, contains('Licúa todo'));
  });

  testWidgets('el texto plano de siempre se sigue viendo igual', (tester) async {
    await _pump(tester, '¡Hola! 👋 ¿Qué cocinamos hoy?');

    expect(_visibleText(tester), contains('¡Hola! 👋 ¿Qué cocinamos hoy?'));
  });
}

Iterable<TextSpan> _spans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _spans(child);
    }
  }
}
