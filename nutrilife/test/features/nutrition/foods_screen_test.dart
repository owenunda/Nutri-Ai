import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/foods_screen.dart';

FoodModel _food(int id, String name, {bool global = true}) => FoodModel(
      foodId: id,
      name: name,
      caloriesPerUnit: 100,
      baseUnit: '100 G',
      isGlobal: global,
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
  _RepoFalso([this.foods]);
  final List<FoodModel>? foods;

  final created = <(String, double, String)>[];

  @override
  Future<List<FoodModel>> getFoods() async => [...(foods ?? _foods)];

  @override
  Future<FoodModel> createFood({
    required String name,
    required double caloriesPerUnit,
    required String baseUnit,
  }) async {
    created.add((name, caloriesPerUnit, baseUnit));
    return _food(99, name, global: false);
  }
}

Future<_RepoFalso> _pump(WidgetTester tester, [List<FoodModel>? foods]) async {
  final repo = _RepoFalso(foods);
  // Alto suficiente para que la lista no dependa del scroll.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: FoodsScreen(foodRepository: repo)),
  ));
  await tester.pumpAndSettle();
  return repo;
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

  testWidgets('la unidad base se elige de una lista y por defecto es 100 g',
      (tester) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('ENTRADA MANUAL'));
    await tester.pumpAndSettle();

    final unitField = find.byKey(const ValueKey('unit-field'));
    expect(find.descendant(of: unitField, matching: find.text('100 g')), findsOneWidget);

    await tester.tap(unitField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 unidad').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del alimento'), 'Arepa');
    await tester.enterText(find.widgetWithText(TextFormField, 'Calorías (Kcal)'), '180');
    await tester.tap(find.text('Guardar Alimento'));
    await tester.pumpAndSettle();

    expect(repo.created.single, ('Arepa', 180.0, '1 UNIDAD'));
  });

  group('pestañas', () {
    final mixed = [
      _food(1, 'Tilapia'),
      _food(2, 'Mi batido', global: false),
      _food(3, 'Arroz'),
    ];

    testWidgets('abre en mis alimentos y separa los comunes', (tester) async {
      await _pump(tester, mixed);

      expect(find.text('Mi batido'), findsOneWidget);
      expect(find.text('Tilapia'), findsNothing);

      await tester.tap(find.text('Comunes'));
      await tester.pumpAndSettle();

      expect(find.text('Tilapia'), findsOneWidget);
      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Mi batido'), findsNothing);
    });

    testWidgets('sin alimentos propios abre en comunes', (tester) async {
      await _pump(tester);
      expect(find.text('Tilapia'), findsOneWidget);

      await tester.tap(find.text('Mis alimentos'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aún no agregaste'), findsOneWidget);
    });

    testWidgets('al buscar mezcla las dos', (tester) async {
      await _pump(tester, mixed);

      await tester.enterText(_search, 'i');
      await tester.pumpAndSettle();

      expect(find.text('Mi batido'), findsOneWidget);
      expect(find.text('Tilapia'), findsOneWidget);
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

      expect(find.text('Alimentos comunes'), findsOneWidget);
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
