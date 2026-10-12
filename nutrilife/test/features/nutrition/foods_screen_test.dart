import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/foods_screen.dart';

FoodModel _food(int id, String name) => FoodModel(
      foodId: id,
      name: name,
      caloriesPerUnit: 100,
      baseUnit: '100 G',
      isGlobal: true,
      isActive: true,
    );

final _foods = [
  _food(1, 'Tilapia'),
  _food(2, 'Camarón'),
  _food(3, 'Jamón'),
  _food(4, 'Salmón'),
  _food(5, 'Arroz'),
  _food(6, 'Banana'),
  _food(7, 'Pera'),
];

class _RepoFalso extends FoodRepository {
  @override
  Future<List<FoodModel>> getFoods() async => _foods;
}

Future<void> _pump(WidgetTester tester) async {
  // Alto suficiente para que la lista no dependa del scroll.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: FoodsScreen(foodRepository: _RepoFalso())),
  ));
  await tester.pumpAndSettle();
}

Finder get _search => find.byType(TextField);

void main() {
  group('buscador', () {
    testWidgets('la X aparece al escribir y borra la búsqueda', (tester) async {
      await _pump(tester);
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);

      await tester.enterText(_search, 'tila');
      await tester.pump();
      expect(find.text('Camarón'), findsNothing);

      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
      expect(find.byTooltip('Borrar búsqueda'), findsNothing);
    });

    testWidgets('al buscar se esconde la tarjeta y se ven los resultados',
        (tester) async {
      await _pump(tester);
      expect(find.text('Agregar personalizado'), findsOneWidget);

      await tester.tap(_search);
      await tester.enterText(_search, 'pera');
      await tester.pumpAndSettle();

      expect(find.text('Agregar personalizado'), findsNothing);
      expect(find.text('Resultados (1)'), findsOneWidget);
      expect(find.text('Pera'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo dice en vez de "base vacía"',
        (tester) async {
      await _pump(tester);

      await tester.enterText(_search, 'zzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos'), findsOneWidget);
      expect(find.text('No hay alimentos cargados'), findsNothing);
    });
  });

  group('Ver todo', () {
    testWidgets('la vista normal muestra solo los primeros 5', (tester) async {
      await _pump(tester);

      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('abre la lista completa', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();

      expect(find.text('Todos los alimentos'), findsOneWidget);
      expect(find.text('7 alimentos'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Pera'), findsOneWidget);
    });

    testWidgets('la lista completa también filtra', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();

      await tester.enterText(_search, 'sal');
      await tester.pumpAndSettle();

      expect(find.text('Salmón'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('1 alimento'), findsOneWidget);
    });
  });
}
