import '../../../chatbot/data/models/recipe_model.dart';
import '../../domain/meal_type.dart';

class MealItem {
  final int detailId;
  final int foodId;
  final String name;
  final String baseUnit;
  final double quantity;
  final int calories;

  /// Receta del chat de la que salió este ingrediente, si salió de una.
  final int? recipeLogId;

  const MealItem({
    required this.detailId,
    required this.foodId,
    required this.name,
    required this.baseUnit,
    required this.quantity,
    required this.calories,
    this.recipeLogId,
  });

  factory MealItem.fromJson(Map map) => MealItem(
    detailId: (map['detailId'] as num).toInt(),
    foodId: (map['foodId'] as num).toInt(),
    name: map['name'] as String? ?? '',
    baseUnit: map['baseUnit'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
    calories: (map['calories'] as num?)?.round() ?? 0,
    recipeLogId: (map['recipeLogId'] as num?)?.toInt(),
  );
}

/// Una receta del chat registrada como comida (la guarda el backend).
class LoggedRecipe {
  final int id;
  final String title;
  final double portions;
  final RecipeModel recipe;

  const LoggedRecipe({
    required this.id,
    required this.title,
    required this.portions,
    required this.recipe,
  });

  factory LoggedRecipe.fromJson(int id, Map map) => LoggedRecipe(
    id: id,
    title: map['title'] as String? ?? '',
    portions: (map['portions'] as num?)?.toDouble() ?? 1,
    recipe: RecipeModel.fromMap(map['recipe'] as Map? ?? const {}),
  );
}

class MealGroup {
  final MealType type;
  final int totalCalories;
  final List<MealItem> items;

  /// Recetas de las que salieron algunos [items], por id.
  final Map<int, LoggedRecipe> recipes;

  const MealGroup({
    required this.type,
    required this.totalCalories,
    required this.items,
    this.recipes = const {},
  });

  bool get isEmpty => items.isEmpty;

  /// La receta de [item], si salió de una que el backend devolvió.
  LoggedRecipe? recipeOf(MealItem item) =>
      item.recipeLogId == null ? null : recipes[item.recipeLogId];

  /// "Tilapia, Arroz • 240 kcal" o "Aún no registrada". Los ingredientes de
  /// una receta se nombran con la receta, una sola vez.
  String get summary {
    if (isEmpty) return 'Aún no registrada';
    final names = <String>[];
    final seenRecipes = <int>{};
    for (final item in items) {
      final recipe = recipeOf(item);
      if (recipe == null) {
        names.add(item.name);
      } else if (seenRecipes.add(recipe.id)) {
        names.add(recipe.title);
      }
    }
    return '${names.join(', ')} • $totalCalories kcal';
  }

  factory MealGroup.fromJson(
    MealType type,
    Map? map, [
    Map<int, LoggedRecipe> recipes = const {},
  ]) => MealGroup(
    type: type,
    totalCalories: (map?['totalCalories'] as num?)?.round() ?? 0,
    items: (map?['items'] as List? ?? const [])
        .whereType<Map>()
        .map(MealItem.fromJson)
        .toList(),
    recipes: recipes,
  );
}

class DayMeals {
  final String date;
  final int totalCalories;
  final Map<MealType, MealGroup> _groups;

  DayMeals({
    required this.date,
    required this.totalCalories,
    required this._groups,
  });

  MealGroup of(MealType type) =>
      _groups[type] ?? MealGroup(type: type, totalCalories: 0, items: const []);

  factory DayMeals.fromJson(Map map) {
    final meals = map['meals'] as Map? ?? const {};
    final recipes = <int, LoggedRecipe>{
      for (final entry in (map['recipes'] as Map? ?? const {}).entries)
        if (int.tryParse('${entry.key}') != null && entry.value is Map)
          int.parse('${entry.key}'): LoggedRecipe.fromJson(
            int.parse('${entry.key}'),
            entry.value as Map,
          ),
    };
    return DayMeals(
      date: map['date'] as String? ?? '',
      totalCalories: (map['totalCalories'] as num?)?.round() ?? 0,
      groups: {
        for (final type in MealType.values)
          type: MealGroup.fromJson(type, meals[type.apiValue] as Map?, recipes),
      },
    );
  }

  factory DayMeals.empty(String date) =>
      DayMeals(date: date, totalCalories: 0, groups: const {});
}
