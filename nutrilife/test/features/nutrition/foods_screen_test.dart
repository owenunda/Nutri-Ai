import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/domain/food_units.dart';
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

class _MealRepoFalso extends MealRepository {
  _MealRepoFalso() : super(dio: Dio());

  int? foodId;
  double? portions;
  MealType? mealType;

  @override
  Future<int> addFood({
    required int foodId,
    required double portions,
    required MealType type,
    DateTime? now,
  }) async {
    this.foodId = foodId;
    this.portions = portions;
    mealType = type;
    return 1;
  }
}

Future<_RepoFalso> _pump(
  WidgetTester tester, [
  List<FoodModel>? foods,
  Size physicalSize = const Size(1080, 3200),
  double devicePixelRatio = 2.5,
  MealRepository? mealRepository,
]) async {
  final repo = _RepoFalso(foods);
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FoodsScreen(foodRepository: repo, mealRepository: mealRepository),
      ),
    ),
  );
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

    testWidgets('al buscar se esconde la tarjeta y se ven los resultados', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Agregar personalizado'), findsOneWidget);

      await tester.tap(_search);
      await tester.enterText(_search, 'pera');
      await tester.pumpAndSettle();

      expect(find.text('Agregar personalizado'), findsNothing);
      expect(find.text('Resultados (1)'), findsOneWidget);
      expect(find.text('Pera'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo dice en vez de "base vacía"', (
      tester,
    ) async {
      await _pump(tester);

      await tester.enterText(_search, 'zzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos'), findsOneWidget);
      expect(find.text('No hay alimentos cargados'), findsNothing);
    });
  });

  testWidgets('la unidad base se elige de una lista y por defecto es 100 g', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await tester.tap(find.text('A mi nevera'));
    await tester.pumpAndSettle();

    final unitField = find.byKey(const ValueKey('unit-field'));
    expect(
      find.descendant(of: unitField, matching: find.text('100 g')),
      findsOneWidget,
    );

    await tester.tap(unitField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 unidad').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del alimento'),
      'Arepa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías (Kcal)'),
      '180',
    );
    await tester.tap(find.text('Guardar en nevera'));
    await tester.pumpAndSettle();

    expect(repo.created.single, ('Arepa', 180.0, '1 UNIDAD'));
  });

  testWidgets('sugiere reutilizar un alimento existente al registrar consumo', (
    tester,
  ) async {
    final mealRepository = _MealRepoFalso();
    final foodRepository = await _pump(
      tester,
      _foods,
      const Size(1080, 3200),
      2.5,
      mealRepository,
    );

    await tester.tap(find.text('Lo consumí'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del alimento'),
      'tila',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe un alimento parecido. Elige uno para usarlo:'),
      findsOneWidget,
    );
    final lunchChip = find.byKey(const ValueKey('meal-type-LUNCH'));
    await tester.ensureVisible(lunchChip);
    await tester.tap(lunchChip);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(lunchChip).selected, isTrue);

    final existingFood = find.byKey(const ValueKey('existing-food-1'));
    await tester.ensureVisible(existingFood);
    await tester.tap(existingFood);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-existing-food')),
      findsOneWidget,
    );
    expect(find.text('Calorías (Kcal)'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('manual-food-quantity')),
      '2',
    );
    await tester.ensureVisible(find.text('Registrar consumo'));
    await tester.tap(find.text('Registrar consumo'));
    await tester.pumpAndSettle();

    expect(foodRepository.created, isEmpty);
    expect(mealRepository.foodId, 1);
    expect(mealRepository.portions, 2);
    expect(mealRepository.mealType, MealType.lunch);
  });

  testWidgets('muestra primero el buscador y la tarjeta personalizada', (
    tester,
  ) async {
    await _pump(tester);

    final searchTop = tester.getTopLeft(_search).dy;
    final customCardTop = tester
        .getTopLeft(find.text('Agregar personalizado'))
        .dy;
    final titleTop = tester.getTopLeft(find.text('Mi nevera').first).dy;

    expect(searchTop, lessThan(customCardTop));
    expect(customCardTop, lessThan(titleTop));
  });

  group('pestañas', () {
    final mixed = [
      _food(1, 'Tilapia'),
      _food(2, 'Mi batido', global: false),
      _food(3, 'Arroz'),
    ];

    testWidgets('abre en comunes si la nevera está vacía', (tester) async {
      await _pump(tester, mixed);

      expect(find.text('Tilapia'), findsOneWidget);
      expect(find.text('Mi batido'), findsNothing);

      await tester.tap(find.text('Mi nevera').last);
      await tester.pumpAndSettle();

      expect(find.text('Tu nevera está vacía'), findsOneWidget);
      expect(find.text('Mi batido'), findsNothing);
    });

    testWidgets('permite abrir la nevera vacía desde comunes', (tester) async {
      await _pump(tester);
      expect(find.text('Tilapia'), findsOneWidget);

      await tester.tap(find.text('Mi nevera').last);
      await tester.pumpAndSettle();
      expect(find.text('Tu nevera está vacía'), findsOneWidget);
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

    testWidgets('expande la lista completa en la misma pantalla', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Pera'), findsOneWidget);
      expect(find.text('Alimentos comunes'), findsNothing);
      expect(find.text('Ver menos'), findsOneWidget);
    });

    testWidgets('la lista expandida también filtra', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();

      await tester.enterText(_search, 'sal');
      await tester.pumpAndSettle();

      expect(find.text('Salmón'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('cada alimento permite elegir cantidad y destino', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Acciones').first);
      await tester.pumpAndSettle();

      expect(find.text('Cantidad'), findsOneWidget);
      expect(find.text('Unidad'), findsOneWidget);
      expect(find.text('A mi nevera'), findsNWidgets(2));
      expect(find.text('Lo consumí'), findsNWidgets(2));

      await tester.tap(find.text('Lo consumí').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Desayuno'), findsOneWidget);
      expect(find.text('Unidad'), findsNothing);
    });

    testWidgets(
      'las acciones de selección quedan visibles sin bajar al final',
      (tester) async {
        await _pump(tester, null, const Size(400, 700), 1);
        await tester.ensureVisible(find.text('Tilapia'));
        await tester.tap(find.text('Tilapia'));
        await tester.pumpAndSettle();

        expect(find.text('1 alimento seleccionado'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'A mi nevera'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Lo consumí'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Lo consumí'));
        await tester.pumpAndSettle();

        expect(find.text('¿En qué comida?'), findsOneWidget);
        expect(find.text('Desayuno'), findsOneWidget);
      },
    );
  });

  test('formatea cantidades sin repetir la unidad', () {
    expect(formatQuantityWithUnit(1, '1 UNIDAD'), '1 unidad');
    expect(formatQuantityWithUnit(2, '1 UNIDAD'), '2 unidades');
    expect(formatQuantityWithUnit(1, '1 unidad'), '1 unidad');
    expect(formatQuantityWithUnit(1, '100 G'), '1 100 g');
    expect(formatQuantityWithUnit(2.5, '100 G'), '2.5 100 g');
  });
}
