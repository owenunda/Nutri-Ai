import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/l10n/app_localizations.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o);
    final data = routes['${o.method} ${o.path}'];
    return ResponseBody.fromString(
      jsonEncode(data == null
          ? {'success': false, 'message': 'Ítem no encontrado'}
          : {'success': true, 'data': data}),
      data == null ? 404 : 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

(MealRepository, _Adapter) _repo(Map<String, Object> routes) {
  final adapter = _Adapter(routes);
  return (
    MealRepository(dio: Dio(BaseOptions(baseUrl: 'https://t.local'))..httpClientAdapter = adapter),
    adapter,
  );
}

final _es = lookupAppLocalizations(const Locale('es'));

void main() {
  test('addFood crea el registro del día local y agrega con meal_type', () async {
    final (repo, adapter) = _repo({
      'POST /meals': {'mealRecordId': 9},
      'POST /meals/9/items': [
        {'detailId': 41, 'foodId': 3, 'quantity': 1.5, 'mealType': 'LUNCH'}
      ],
    });

    final id = await repo.addFood(
      foodId: 3,
      portions: 1.5,
      type: MealType.lunch,
      now: DateTime(2026, 10, 12, 23, 30),
    );

    expect(id, 41);
    expect(adapter.requests[0].data, {'date': '2026-10-12'});
    expect(adapter.requests[1].data, [
      {'food_id': 3, 'quantity': 1.5, 'meal_type': 'LUNCH'}
    ]);
  });

  test('addFoods registra varios alimentos en una sola llamada', () async {
    final (repo, adapter) = _repo({
      'POST /meals': {'mealRecordId': 9},
      'POST /meals/9/items': [
        {'detailId': 50, 'foodId': 3, 'quantity': 0.5, 'mealType': 'DINNER'},
        {'detailId': 51, 'foodId': 4, 'quantity': 0.25, 'mealType': 'DINNER'},
      ],
    });

    final ids = await repo.addFoods(
      items: [(foodId: 3, quantity: 0.5), (foodId: 4, quantity: 0.25)],
      type: MealType.dinner,
      now: DateTime(2026, 10, 12, 20),
    );

    expect(ids, [50, 51]);
    expect(adapter.requests[1].data, [
      {'food_id': 3, 'quantity': 0.5, 'meal_type': 'DINNER'},
      {'food_id': 4, 'quantity': 0.25, 'meal_type': 'DINNER'},
    ]);
  });

  test('addRecipe manda la receta, las porciones y los ingredientes', () async {
    final (repo, adapter) = _repo({
      'POST /meals': {'mealRecordId': 9},
      'POST /meals/9/recipe-log': {
        'recipeLogId': 12,
        'items': [
          {'detailId': 50, 'foodId': 5, 'quantity': 0.75, 'mealType': 'DINNER'},
        ],
      },
    });
    const recipe = RecipeModel(
      title: 'Pollo', summary: 'Rico', chefReason: '', mealType: 'cena', difficulty: '',
      preparationTimeMinutes: 20, servings: 4, estimatedCalories: 500, tips: [],
      steps: [RecipeStep(step: 1, description: 'Cocinar')],
      ingredients: [RecipeIngredient(foodId: 5, quantity: 300)],
    );

    final saved = await repo.addRecipe(
      recipe: recipe,
      portions: 1,
      items: [(foodId: 5, quantity: 0.75)],
      type: MealType.dinner,
      now: DateTime(2026, 10, 12, 20),
    );

    expect(saved.recipeLogId, 12);
    expect(saved.detailIds, [50]);
    final body = adapter.requests[1].data as Map;
    expect((body['recipe'] as Map)['recipe_title'], 'Pollo');
    expect(body['portions'], 1);
    expect(body['meal_type'], 'DINNER');
    expect(body['items'], [
      {'food_id': 5, 'quantity': 0.75}
    ]);
  });

  test('deleteRecipeLog borra la receta por su id', () async {
    final (repo, adapter) = _repo({'DELETE /meals/recipe-logs/12': {'recipeLogId': 12}});
    await repo.deleteRecipeLog(12);
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/meals/recipe-logs/12');
  });

  test('getDay trae las recetas registradas y agrupa sus ingredientes', () async {
    final (repo, _) = _repo({
      'GET /meals/day': {
        'date': '2026-10-12',
        'totalCalories': 124,
        'meals': {
          'DINNER': {
            'totalCalories': 124,
            'items': [
              {'detailId': 50, 'foodId': 5, 'name': 'Pechuga', 'baseUnit': '100 G', 'quantity': 0.75, 'calories': 124, 'recipeLogId': 12},
            ],
          },
        },
        'recipes': {
          '12': {
            'title': 'Pollo al ajillo',
            'portions': 1,
            'recipe': {'recipe_title': 'Pollo al ajillo', 'steps': [{'step': 1, 'description': 'Cocinar'}]},
          },
        },
      },
    });

    final day = await repo.getDay('2026-10-12');
    final cena = day.of(MealType.dinner);
    expect(cena.summary(_es), 'Pollo al ajillo • 124 kcal');
    final recipe = cena.recipeOf(cena.items.single)!;
    expect(recipe.id, 12);
    expect(recipe.recipe.steps.single.description, 'Cocinar');
  });

  test('getDay arma los grupos y el resumen', () async {
    final (repo, adapter) = _repo({
      'GET /meals/day': {
        'date': '2026-10-12',
        'totalCalories': 240,
        'meals': {
          'BREAKFAST': {'totalCalories': 0, 'items': []},
          'LUNCH': {
            'totalCalories': 240,
            'items': [
              {'detailId': 1, 'foodId': 3, 'name': 'Tilapia', 'baseUnit': '100 G', 'quantity': 1.5, 'calories': 144},
              {'detailId': 2, 'foodId': 5, 'name': 'Arroz', 'baseUnit': '100 G', 'quantity': 1, 'calories': 96},
            ]
          },
          'DINNER': {'totalCalories': 0, 'items': []},
          'SNACK': {'totalCalories': 0, 'items': []},
        }
      },
    });

    final day = await repo.getDay('2026-10-12');

    expect(adapter.requests.single.queryParameters, {'date': '2026-10-12'});
    expect(day.totalCalories, 240);
    expect(day.of(MealType.lunch).summary(_es), 'Tilapia, Arroz • 240 kcal');
    expect(day.of(MealType.breakfast).isEmpty, isTrue);
  });

  test('deleteItem propaga el mensaje del backend', () async {
    final (repo, _) = _repo({});
    expect(
      repo.deleteItem(7),
      throwsA(isA<Exception>().having((e) => '$e', 'msg', contains('Ítem no encontrado'))),
    );
  });
}
