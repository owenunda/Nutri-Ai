import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/domain/portions.dart';
import 'package:nutrilife/features/meals/presentation/screens/meal_history_screen.dart';
import 'package:nutrilife/features/meals/presentation/widgets/day_meals_list.dart';
import 'package:nutrilife/features/meals/presentation/widgets/register_recipe_sheet.dart';
import 'package:nutrilife/l10n/app_localizations.dart';

import '../../helpers/l10n_app.dart';

class _RepoVacio extends MealRepository {
  @override
  Future<DayMeals> getDay(String date) async => DayMeals.empty(date);
}

RecipeModel _recipe(String mealType) => RecipeModel(
      title: 'Pollo',
      summary: '',
      chefReason: '',
      mealType: mealType,
      difficulty: '',
      preparationTimeMinutes: 10,
      servings: 2,
      estimatedCalories: 100,
      tips: const [],
      steps: const [],
      ingredients: const [],
    );

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('MealType', () {
    test('el nombre cambia con el idioma y el valor del backend no', () {
      expect(MealType.breakfast.label(es), 'Desayuno');
      expect(MealType.breakfast.label(en), 'Breakfast');
      expect(MealType.snack.label(en), 'Snack');
      expect(MealType.values.map((t) => t.apiValue), ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK']);
    });

    test('el tipo que escribe el chef se entiende en español aunque la app esté en inglés', () {
      expect(mealTypeOfRecipe(_recipe('Cena')), MealType.dinner);
      expect(mealTypeOfRecipe(_recipe('desayuno')), MealType.breakfast);
      expect(mealTypeOfRecipe(_recipe('Breakfast')), isNull);
    });
  });

  group('porciones', () {
    test('portionsText y mealItemLabel en inglés', () {
      expect(portionsText(0.5, en), '½ serving');
      expect(portionsText(1.5, en), '1½ servings');
      expect(mealItemLabel(1.5, '100 G', en), '1½ servings · 150 g');
      expect(mealItemLabel(1, '100 G COCIDO', es), '1 porción · 100 g cocido');
    });
  });

  test('el separador decimal de los ingredientes sigue al idioma', () {
    expect(ingredientAmountLabel(0.25, '1 UNIDAD', en), '0.25 units');
    expect(ingredientAmountLabel(0.25, '1 UNIDAD', es), '0,25 unidad');
    expect(ingredientAmountLabel(0.5, '1 UNIDAD', en), '0.5 units');
    expect(ingredientAmountLabel(2, '1 UNIDAD', en), '2 units');
    expect(ingredientAmountLabel(1, '1 UNIDAD', en), '1 unit');
    expect(mealItemLabel(0.17, '1 UNIDAD', en), '0.17 units');
  });

  test('el nombre de la unidad de los ingredientes sale en el idioma', () {
    expect(ingredientAmountLabel(2, '1 TAZA', en), '2 cups');
    expect(ingredientAmountLabel(2, '1 TAZA', es), '2 taza');
    expect(ingredientAmountLabel(1.5, 'cucharada', en), '1.5 tablespoons');
    expect(ingredientAmountLabel(3, '2 grandes', en), '3 grandes');
    expect(quantityLabel(1.5, '1 UNIDAD', en), '1½ units');
    expect(quantityLabel(1, '1 UNIDAD', en), '1 unit');
    expect(quantityLabel(1.5, '1 UNIDAD', es), '1½ unidad');
    expect(quantityLabel(1.5, '100 G', en), '150 g');
    expect(mealItemLabel(1.5, '1 REBANADA', en), '1½ servings · 1½ slices');
  });

  test('el aviso de borrar receta distingue 1 ingrediente de varios', () {
    expect(es.mealsDeleteRecipeBody('Pollo', 1), 'Se quitará "Pollo" con su ingrediente de esta comida.');
    expect(es.mealsDeleteRecipeBody('Pollo', 3), 'Se quitará "Pollo" con sus 3 ingredientes de esta comida.');
    expect(en.mealsDeleteRecipeBody('Pollo', 1), '"Pollo" will be removed from this meal along with its ingredient.');
    expect(en.mealsDeleteRecipeBody('Pollo', 3), '"Pollo" will be removed from this meal along with its 3 ingredients.');
  });

  testWidgets('las tarjetas del día salen en inglés', (tester) async {
    await tester.pumpWidget(l10nApp(
      Scaffold(body: SingleChildScrollView(child: DayMealsList(day: DayMeals.empty('2026-10-12'), onOpen: (_) {}))),
      locale: const Locale('en'),
    ));
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Not logged yet'), findsNWidgets(4));
  });

  testWidgets('el historial usa la fecha y los textos en inglés', (tester) async {
    await tester.pumpWidget(l10nApp(
      MealHistoryScreen(repository: _RepoVacio(), clock: () => DateTime(2026, 10, 12, 9)),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Meal history'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Sat, Oct 10'), findsOneWidget);
  });

  testWidgets('el historial en español muestra la fecha como siempre', (tester) async {
    await tester.pumpWidget(l10nApp(
      MealHistoryScreen(repository: _RepoVacio(), clock: () => DateTime(2026, 10, 12, 9)),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Día anterior'));
    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sáb 10 oct'), findsOneWidget);
  });
}
