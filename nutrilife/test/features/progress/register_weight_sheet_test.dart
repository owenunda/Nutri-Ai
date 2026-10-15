import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';
import 'package:nutrilife/features/progress/presentation/widgets/register_weight_sheet.dart';

import '../../helpers/l10n_app.dart';

class _RepoFalso extends ProgressRepository {
  final saved = <(double, double)>[];

  @override
  Future<void> addWeight({required double weight, required double height}) async {
    saved.add((weight, height));
  }
}

Future<_RepoFalso> _open(
  WidgetTester tester, {
  double? weight = 80,
  double? height = 175,
  Locale locale = const Locale('es'),
}) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(l10nApp(
    locale: locale,
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRegisterWeightSheet(context, lastWeight: weight, height: height, repository: repo),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('precarga el último peso y ajusta de a 0,1', (tester) async {
    final repo = await _open(tester);
    expect(find.text('80,0'), findsOneWidget);

    await tester.tap(find.byTooltip('Sumar 0,1 kg'));
    await tester.pump();
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    expect(repo.saved.single, (80.1, 175.0));
  });

  testWidgets('el peso solo acepta números con un decimal', (tester) async {
    await _open(tester);
    final field = find.byKey(const ValueKey('weight-field'));

    await tester.enterText(field, 'abc');
    expect(find.text('80,0'), findsOneWidget);

    await tester.enterText(field, '72,5');
    expect(find.text('72,5'), findsOneWidget);

    await tester.enterText(field, '72.55');
    expect(find.text('72,5'), findsOneWidget);

    await tester.enterText(field, '1234');
    expect(find.text('72,5'), findsOneWidget);
  });

  testWidgets('rechaza pesos fuera de rango', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(find.byKey(const ValueKey('weight-field')), '20');
    await tester.tap(find.text('Guardar peso'));
    await tester.pump();

    expect(find.text('El peso debe estar entre 30 y 300 kg'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('en inglés usa punto decimal y textos en inglés', (tester) async {
    final repo = await _open(tester, locale: const Locale('en'));
    expect(find.text('Log weight'), findsOneWidget);
    expect(find.text('Last entry: 80.0 kg'), findsOneWidget);
    expect(find.text('80.0'), findsOneWidget);

    await tester.tap(find.byTooltip('Add 0.1 kg'));
    await tester.pump();
    expect(find.text('80.1'), findsOneWidget);
    expect(find.text('+0.1 kg since last time'), findsOneWidget);

    await tester.tap(find.byTooltip('Subtract 0.1 kg'));
    await tester.tap(find.byTooltip('Subtract 0.1 kg'));
    await tester.pump();
    expect(find.text('−0.1 kg since last time'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('weight-field')), '20');
    await tester.tap(find.text('Save weight'));
    await tester.pump();
    expect(find.text('Weight must be between 30 and 300 kg'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('en español muestra la diferencia con coma', (tester) async {
    await _open(tester);
    await tester.tap(find.byTooltip('Sumar 0,1 kg'));
    await tester.pump();
    expect(find.text('+0,1 kg desde el último'), findsOneWidget);
    expect(find.text('Último registro: 80,0 kg'), findsOneWidget);
  });

  testWidgets('sin altura en el perfil la pide', (tester) async {
    final repo = await _open(tester, height: null);
    await tester.enterText(find.byKey(const ValueKey('height-field')), '170');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    expect(repo.saved.single, (80.0, 170.0));
  });
}
