import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/recipe_card_widget.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/data/recipe_meal_links.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/presentation/widgets/meal_detail_sheet.dart';
import 'package:nutrilife/features/meals/presentation/widgets/register_recipe_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoFalso extends MealRepository {
  final added = <(List<({int foodId, double quantity})>, MealType)>[];
  final deleted = <int>[];

  @override
  Future<List<int>> addFoods({
    required List<({int foodId, double quantity})> items,
    required MealType type,
    DateTime? now,
  }) async {
    added.add((items, type));
    return [for (var i = 0; i < items.length; i++) 100 + i];
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

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
    RecipeIngredient(foodId: 4, quantity: 2),
  ],
);

Future<_RepoFalso> _open(WidgetTester tester, RecipeModel recipe) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRegisterRecipeSheet(
            context,
            recipe,
            repository: repo,
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ingredientsFor reparte la receta por porción con dos decimales', () {
    final items = ingredientsFor(_ensalada, 1);
    expect(items.map((i) => (i.foodId, i.quantity)), [(3, 0.5), (4, 0.33)]);
    expect(ingredientsFor(_ensalada, 1.5).map((i) => i.quantity), [0.75, 0.5]);
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

  testWidgets('registra porciones en la comida de la receta y la recuerda', (tester) async {
    final repo = await _open(tester, _ensalada);

    expect(find.text('Registrar en Cena'), findsOneWidget);
    expect(find.text('≈68 kcal · la receta rinde 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Más porciones'));
    await tester.pump();
    expect(find.text('1½ porciones'), findsOneWidget);

    await tester.tap(find.text('Registrar en Cena'));
    await tester.pumpAndSettle();

    final (items, type) = repo.added.single;
    expect(type, MealType.dinner);
    expect(items.map((i) => i.quantity), [0.75, 0.5]);
    expect(find.text('Registrado en Cena · ≈101 kcal'), findsOneWidget);

    final links = await const RecipeMealLinks().byDetailId();
    expect(links.keys, [100, 101]);
    expect(links[100]!.recipe.title, _ensalada.title);
    expect(links[100]!.portions, 1.5);
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

  testWidgets('Deshacer borra todos los ingredientes registrados', (tester) async {
    final repo = await _open(tester, _ensalada);
    await tester.tap(find.text('Registrar en Cena'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(repo.deleted, [100, 101]);
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
    await const RecipeMealLinks().save(
      const RecipeLink(recipe: _ensalada, portions: 1, detailIds: [100, 101]),
    );
    const group = MealGroup(type: MealType.dinner, totalCalories: 160, items: [
      MealItem(detailId: 100, foodId: 3, name: 'Banana', baseUnit: '1 UNIDAD', quantity: 0.5, calories: 45),
      MealItem(detailId: 101, foodId: 4, name: 'Pera', baseUnit: '100 G', quantity: 0.33, calories: 19),
      MealItem(detailId: 7, foodId: 9, name: 'Arroz', baseUnit: '100 G', quantity: 1, calories: 96),
    ]);
    final repo = _RepoFalso();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMealDetailSheet(context, group, repository: repo),
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
    expect(repo.deleted, isEmpty);

    await tester.tap(find.text('Borrar receta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repo.deleted, [100, 101]);
    expect(find.text('Borrar receta'), findsNothing);
  });

  testWidgets('el historial agrupa la receta y deja verla', (tester) async {
    await const RecipeMealLinks().save(
      const RecipeLink(recipe: _ensalada, portions: 1, detailIds: [100, 101]),
    );
    const group = MealGroup(type: MealType.dinner, totalCalories: 160, items: [
      MealItem(detailId: 100, foodId: 3, name: 'Banana', baseUnit: '1 UNIDAD', quantity: 0.5, calories: 45),
      MealItem(detailId: 101, foodId: 4, name: 'Pera', baseUnit: '100 G', quantity: 0.33, calories: 19),
      MealItem(detailId: 7, foodId: 9, name: 'Arroz', baseUnit: '100 G', quantity: 1, calories: 96),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMealDetailSheet(context, group, repository: _RepoFalso()),
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
}
