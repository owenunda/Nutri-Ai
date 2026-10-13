import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/widgets/segmented_tabs.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: SegmentedTabs(
        labels: const ['Mis alimentos', 'Comunes'],
        selected: selected,
        onChanged: (i) => setState(() => selected = i),
      ),
    );
  }
}

Finder get _pill => find.descendant(
      of: find.byType(AnimatedAlign),
      matching: find.byType(DecoratedBox),
    );

Future<void> _pump(WidgetTester tester, {bool reduceMotion = false}) {
  return tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Scaffold(body: Center(child: _Host())),
    ),
  ));
}

void main() {
  testWidgets('la píldora se desliza hasta la pestaña elegida', (tester) async {
    await _pump(tester);
    final start = tester.getTopLeft(_pill).dx;

    await tester.tap(find.text('Comunes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final middle = tester.getTopLeft(_pill).dx;

    await tester.pumpAndSettle();
    final end = tester.getTopLeft(_pill).dx;

    expect(middle, greaterThan(start));
    expect(middle, lessThan(end));
    expect(end, closeTo(tester.getTopLeft(find.byType(SegmentedTabs)).dx + 4 + 196, 1));
  });

  testWidgets('con "reducir movimiento" cambia sin animar', (tester) async {
    await _pump(tester, reduceMotion: true);

    await tester.tap(find.text('Comunes'));
    await tester.pump();
    await tester.pump();

    expect(
      tester.getTopLeft(_pill).dx,
      closeTo(tester.getTopLeft(find.byType(SegmentedTabs)).dx + 4 + 196, 1),
    );
  });
}
