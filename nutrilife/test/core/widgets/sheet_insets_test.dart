import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/widgets/sheet_insets.dart';

Future<double> _insetWith(WidgetTester tester, MediaQueryData data) async {
  late double inset;
  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: Builder(
        builder: (context) {
          inset = sheetBottomInset(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return inset;
}

void main() {
  testWidgets('sin teclado deja el espacio de la barra de navegación', (tester) async {
    final inset = await _insetWith(
      tester,
      const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
    );
    expect(inset, 48);
  });

  testWidgets('con el teclado abierto deja el espacio del teclado', (tester) async {
    // Con el teclado arriba, Flutter ya no cuenta la barra en padding.
    final inset = await _insetWith(
      tester,
      const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
    );
    expect(inset, 300);
  });
}
