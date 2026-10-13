import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/recipe_card_widget.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/presentation/widgets/meal_detail_sheet.dart';
import 'package:nutrilife/features/meals/presentation/widgets/register_recipe_sheet.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';

class _RepoFalso extends MealRepository {
  final added = <(RecipeModel, double, List<({int foodId, double quantity})>, MealType)>[];
  final deleted = <int>[];
  final deletedRecipes = <int>[];

  @override
  Future<({int recipeLogId, List<int> detailIds})> addRecipe({
    required RecipeModel recipe,
    required double portions,
    required List<({int foodId, double quantity})> items,
    required MealType type,
    DateTime? now,
  }) async {
    added.add((recipe, portions, items, type));
    return (recipeLogId: 12, detailIds: [for (var i = 0; i < items.length; i++) 100 + i]);
  }

  @override
  Future<void> deleteRecipeLog(int recipeLogId) async => deletedRecipes.add(recipeLogId);

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

const _logged = LoggedRecipe(id: 12, title: 'Ensalada dulce de banana y pera', portions: 1, recipe: _ensalada);

// Así llega del backend: los ingredientes apuntan a la receta 12.
const _cena = MealGroup(
  type: MealType.dinner,
  totalCalories: 160,
  items: [
    MealItem(detailId: 100, foodId: 3, name: 'Banana', baseUnit: '1 UNIDAD', quantity: 0.5, calories: 45, recipeLogId: 12),
    MealItem(detailId: 101, foodId: 4, name: 'Pera', baseUnit: '100 G', quantity: 0.33, calories: 19, recipeLogId: 12),
    MealItem(detailId: 7, foodId: 9, name: 'Arroz', baseUnit: '100 G', quantity: 1, calories: 96),
  ],
  recipes: {12: _logged},
);

class _Catalogo extends FoodRepository {
  _Catalogo({this.falla = false});
  final bool falla;

  @override
  Future<List<FoodModel>> getFoods() async {
    if (falla) throw Exception('sin red');
    return [
      FoodModel(foodId: 3, name: 'Banana', caloriesPerUnit: 105, baseUnit: '1 UNIDAD', isGlobal: true, isActive: true),
      FoodModel(foodId: 4, name: 'Pera', caloriesPerUnit: 57, baseUnit: '100 G', isGlobal: true, isActive: true),
      FoodModel(foodId: 5, name: 'Pechuga de pollo', caloriesPerUnit: 165, baseUnit: '100 G', isGlobal: true, isActive: true),
    ];
  }
}

final _foods = {
  3: FoodModel(foodId: 3, name: 'Banana', caloriesPerUnit: 105, baseUnit: '1 UNIDAD', isGlobal: true, isActive: true),
  4: FoodModel(foodId: 4, name: 'Pera', caloriesPerUnit: 57, baseUnit: '100 G', isGlobal: true, isActive: true),
};

// El chef da cantidades naturales para toda la receta: 3 bananas, 300 g de pera.
const _ensalada = RecipeModel(
  title: 'Ensalada dulce de banana y pera',
  summary: 'Fresca y ligera',
  chefReason: '',
  mealType: 'cena',
  difficulty: 'fácil',
  preparationTimeMinutes: 10,
  servings: 6,
  estimatedCalories: 405,
  tips: ['Sirve frío'],
  steps: [RecipeStep(step: 1, description: 'Corta la fruta')],
  ingredients: [
    RecipeIngredient(foodId: 3, quantity: 3),
    RecipeIngredient(foodId: 4, quantity: 300),
  ],
);

Future<_RepoFalso> _open(WidgetTester tester, RecipeModel recipe, {bool catalogoFalla = false}) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRegisterRecipeSheet(
            context,
            recipe,
            repository: repo,
            foodRepository: _Catalogo(falla: catalogoFalla),
            clock: () => DateTime(2026, 10, 12, 9),
          ),
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
  test('ingredientsFor reparte por porción y pasa a unidades base', () {
    // 3 bananas / 6 = 0,5 unidad; 300 g / 6 = 50 g = 0,5 de "100 G".
    final items = ingredientsFor(_ensalada, 1, _foods);
    expect(items.map((i) => (i.foodId, i.quantity)), [(3, 0.5), (4, 0.5)]);
    expect(ingredientsFor(_ensalada, 1.5, _foods).map((i) => i.quantity), [0.75, 0.75]);
    expect(caloriesOf(items, _foods), 81);
  });

  test('300 g de pollo en 4 porciones no se vuelven 7,5 kg', () {
    const pollo = RecipeModel(
      title: 'Pollo', summary: '', chefReason: '', mealType: 'cena', difficulty: '',
      preparationTimeMinutes: 0, servings: 4, estimatedCalories: 0, tips: [], steps: [],
      ingredients: [RecipeIngredient(foodId: 5, quantity: 300)],
    );
    final foods = {
      5: FoodModel(foodId: 5, name: 'Pechuga', caloriesPerUnit: 165, baseUnit: '100 G', isGlobal: true, isActive: true),
    };
    final items = ingredientsFor(pollo, 1, foods);
    expect(items.single.quantity, 0.75); // 75 g
    expect(caloriesOf(items, foods), 124);
  });

  test('mealTypeOfRecipe entiende el tipo en español', () {
    expect(mealTypeOfRecipe(_ensalada), MealType.dinner);
  });

  test('RecipeModel sobrevive ida y vuelta a toMap', () {
    final copy = RecipeModel.fromMap(_ensalada.toMap());
    expect(copy.title, _ensalada.title);
    expect(copy.servings, 6);
    expect(copy.steps.single.description, 'Corta la fruta');
    expect(copy.ingredients.map((i) => i.foodId), [3, 4]);
  });

  testWidgets('registra la receta con sus porciones en el backend', (tester) async {
    final repo = await _open(tester, _ensalada);

    expect(find.text('Registrar en Cena'), findsOneWidget);
    expect(find.text('81 kcal · la receta rinde 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Más porciones'));
    await tester.pump();
    expect(find.text('1½ porciones'), findsOneWidget);

    await tester.tap(find.text('Registrar en Cena'));
    await tester.pumpAndSettle();

    final (recipe, portions, items, type) = repo.added.single;
    expect(recipe.title, _ensalada.title);
    expect(portions, 1.5);
    expect(type, MealType.dinner);
    expect(items.map((i) => i.quantity), [0.75, 0.75]);
    expect(find.text('Registrado en Cena · 122 kcal'), findsOneWidget);
  });

  testWidgets('el aviso de registrado se va solo a los pocos segundos', (tester) async {
    await _open(tester, _ensalada);
    await tester.tap(find.text('Registrar en Cena'));
    await tester.pumpAndSettle();
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Deshacer'), findsNothing);
  });

  testWidgets('Deshacer borra la receta entera de una vez', (tester) async {
    final repo = await _open(tester, _ensalada);
    await tester.tap(find.text('Registrar en Cena'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(repo.deletedRecipes, [12]);
    expect(repo.deleted, isEmpty);
  });

  testWidgets('sin los alimentos no deja registrar y ofrece reintentar', (tester) async {
    final repo = await _open(tester, _ensalada, catalogoFalla: true);

    expect(find.text('Reintentar'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Registrar en Cena'));
    expect(button.onPressed, isNull);
    expect(repo.added, isEmpty);
  });

  testWidgets('sin ingredientes avisa y no abre la hoja', (tester) async {
    final repo = await _open(tester, RecipeModel.fromMap(const {'recipe_title': 'Vacía'}));
    expect(find.text('Esta receta no trae ingredientes para registrar'), findsOneWidget);
    expect(find.textContaining('Registrar en'), findsNothing);
    expect(repo.added, isEmpty);
  });

  testWidgets('la tarjeta de receta tiene el botón Registrar comida', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: RecipeCardWidget(recipe: _ensalada))),
    ));
    expect(find.text('Agregar al log diario'), findsNothing);
    await tester.ensureVisible(find.text('Registrar comida'));
    await tester.tap(find.text('Registrar comida'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar en Cena'), findsOneWidget);
  });

  testWidgets('los ingredientes de la receta solo se borran con la receta entera', (tester) async {
    final repo = _RepoFalso();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMealDetailSheet(context, _cena, repository: repo),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Borrar Banana'), findsNothing);
    expect(find.byTooltip('Borrar Pera'), findsNothing);
    expect(find.byTooltip('Borrar Arroz'), findsOneWidget);

    // Cancelar no borra nada.
    await tester.tap(find.text('Borrar receta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar receta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.deletedRecipes, isEmpty);

    await tester.tap(find.text('Borrar receta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repo.deletedRecipes, [12]);
    expect(repo.deleted, isEmpty);
    expect(find.text('Borrar receta'), findsNothing);
  });

  testWidgets('el historial agrupa la receta y deja verla', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMealDetailSheet(context, _cena, repository: _RepoFalso()),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text(_ensalada.title), findsOneWidget);
    expect(find.text('1 porción · 64 kcal'), findsOneWidget);
    expect(find.text('0,5 unidad'), findsOneWidget);
    expect(find.text('33 g'), findsOneWidget);
    expect(find.text('OTROS ALIMENTOS'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);

    await tester.tap(find.text('Ver receta'));
    await tester.pumpAndSettle();
    // Abre la ficha completa, sin volver a ofrecer registrarla.
    expect(find.byType(RecipeCardWidget), findsOneWidget);
    expect(find.text('Fresca y ligera'), findsOneWidget);
    expect(find.text('Registrar comida'), findsNothing);

    await tester.ensureVisible(find.text('Ver receta completa'));
    await tester.tap(find.text('Ver receta completa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Corta la fruta'), findsWidgets);
  });

  test('la tarjeta del día nombra la receta en vez de sus ingredientes', () {
    expect(_cena.summary, 'Ensalada dulce de banana y pera, Arroz • 160 kcal');
  });
}
