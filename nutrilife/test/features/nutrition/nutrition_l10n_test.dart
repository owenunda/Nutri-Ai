import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/domain/food_units.dart';
import 'package:nutrilife/features/nutrition/presentation/screens/foods_screen.dart';
import 'package:nutrilife/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

FoodModel _food(int id, String name, {bool global = true}) => FoodModel(
  foodId: id,
  name: name,
  caloriesPerUnit: 100,
  baseUnit: '100 G',
  isGlobal: global,
  isActive: true,
);

class _RepoFalso extends FoodRepository {
  final created = <(String, double, String)>[];

  @override
  Future<List<FoodModel>> getFoods() async => [
    _food(1, 'Tilapia'),
    _food(2, 'Arroz'),
  ];

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

  MealType? mealType;

  @override
  Future<int> addFood({
    required int foodId,
    required double portions,
    required MealType type,
    DateTime? now,
  }) async {
    mealType = type;
    return 1;
  }
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<_RepoFalso> _pumpEn(WidgetTester tester) async {
  final repo = _RepoFalso();
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    l10nApp(
      Scaffold(
        body: FoodsScreen(foodRepository: repo, mealRepository: _MealRepoFalso()),
      ),
      locale: const Locale('en'),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('unidades', () {
    test('los códigos que se guardan no cambian con el idioma', () {
      expect(kFoodUnitValues, [
        '100 G',
        '100 ML',
        '1 UNIDAD',
        '1 PORCIÓN',
        '1 TAZA',
        '1 CUCHARADA',
        '1 REBANADA',
      ]);
      expect(kDefaultFoodUnit, '100 G');
      expect(
        foodUnitOptions(en).map((o) => o.value),
        foodUnitOptions(es).map((o) => o.value),
      );
    });

    test('nombres de las opciones en español e inglés', () {
      expect(foodUnitOptions(es).map((o) => o.label), [
        '100 g',
        '100 ml',
        '1 unidad',
        '1 porción',
        '1 taza',
        '1 cucharada',
        '1 rebanada',
      ]);
      expect(foodUnitOptions(en).map((o) => o.label), [
        '100 g',
        '100 ml',
        '1 unit',
        '1 serving',
        '1 cup',
        '1 tablespoon',
        '1 slice',
      ]);
    });

    test('prettyUnitLabel traduce las conocidas y deja las demás', () {
      expect(prettyUnitLabel('1 UNIDAD', en), '1 unit');
      expect(prettyUnitLabel('1 unidad', en), '1 unit');
      expect(prettyUnitLabel('1 UNIDAD', es), '1 unidad');
      expect(prettyUnitLabel(' G ', en), 'g');
      expect(prettyUnitLabel('2 grandes', en), '2 grandes');
      expect(prettyUnitLabel('', en), '');
    });

    test('cantidad con unidad: plural según el idioma', () {
      expect(formatQuantityWithUnit(1, '1 UNIDAD', en), '1 unit');
      expect(formatQuantityWithUnit(2, '1 UNIDAD', en), '2 units');
      expect(formatQuantityWithUnit(2.5, '1 TAZA', en), '2.5 cups');
      expect(formatQuantityWithUnit(0.5, '1 REBANADA', en), '0.5 slices');
      expect(formatQuantityWithUnit(3, '1 PORCIÓN', es), '3 porciones');
      expect(formatQuantityWithUnit(1, '1 CUCHARADA', es), '1 cucharada');
      expect(formatQuantityWithUnit(2, '1 CUCHARADA', es), '2 cucharadas');
      expect(formatQuantityWithUnit(2, '1 UNIDAD', es), '2 unidades');
      expect(formatQuantityWithUnit(1.5, '100 G', en), '1.5 100 g');
    });
  });

  group('FoodsScreen en inglés', () {
    testWidgets('textos de la pantalla y de la hoja de agregar', (tester) async {
      await _pumpEn(tester);

      expect(find.text('Add your own'), findsOneWidget);
      expect(find.text('My fridge'), findsWidgets);
      expect(find.text('Common'), findsOneWidget);
      expect(find.text('Mi nevera'), findsNothing);
      expect(find.text('Search over 100,000 foods...'), findsOneWidget);

      await tester.tap(find.text('To my fridge'));
      await tester.pumpAndSettle();
      expect(find.text('Add to my fridge'), findsOneWidget);
      expect(find.text('Food name'), findsOneWidget);
      expect(find.text('Save to fridge'), findsOneWidget);
    });

    testWidgets('elegir una unidad guarda el código sin traducir', (
      tester,
    ) async {
      final repo = await _pumpEn(tester);
      await tester.tap(find.text('To my fridge'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('unit-field')));
      await tester.pumpAndSettle();
      expect(find.text('1 tablespoon'), findsOneWidget);
      await tester.tap(find.text('1 unit').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Food name'),
        'Arepa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calories (kcal)'),
        '180',
      );
      await tester.tap(find.text('Save to fridge'));
      await tester.pumpAndSettle();

      expect(repo.created.single, ('Arepa', 180.0, '1 UNIDAD'));
    });

    testWidgets('selección en lote: contador, comida y resultado', (
      tester,
    ) async {
      await _pumpEn(tester);

      await tester.tap(find.text('Tilapia'));
      await tester.pumpAndSettle();
      expect(find.text('1 food selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'I ate it'));
      await tester.pumpAndSettle();
      expect(find.text('Which meal?'), findsOneWidget);

      await tester.tap(find.text('Breakfast'));
      await tester.pumpAndSettle();
      expect(find.text('1/1 processed successfully.'), findsOneWidget);
    });
  });

  group('FridgeRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(
      () => LocaleState.instance.setPreference(LanguagePreference.system),
    );

    FridgeRepository repo() => FridgeRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://test.local', validateStatus: (_) => true))
        ..httpClientAdapter = _FakeAdapter(500, {'success': false}),
    );

    test('sin mensaje del backend, el error sale en el idioma de la app', () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      await expectLater(
        repo().getFridgeItems(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains("Couldn't load your fridge"),
          ),
        ),
      );

      await LocaleState.instance.setPreference(LanguagePreference.es);
      await expectLater(
        repo().getFridgeItems(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Error al obtener la nevera'),
          ),
        ),
      );
    });
  });
}
