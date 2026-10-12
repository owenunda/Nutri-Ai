import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/widgets/dismiss_keyboard_on_tap.dart';

void main() {
  testWidgets('tocar fuera del campo cierra el teclado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboardOnTap(child: child!),
        home: const Scaffold(
          body: Column(
            children: [
              TextField(key: Key('campo')),
              Expanded(child: SizedBox.expand(key: Key('fondo'))),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('campo')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('fondo')));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('tocar el propio campo no lo cierra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboardOnTap(child: child!),
        home: const Scaffold(body: TextField(key: Key('campo'))),
      ),
    );

    await tester.tap(find.byKey(const Key('campo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('campo')));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });
}
