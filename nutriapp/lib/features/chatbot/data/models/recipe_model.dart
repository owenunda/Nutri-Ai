class RecipeStep {
  final int step;
  final String description;

  const RecipeStep({required this.step, required this.description});

  factory RecipeStep.fromMap(Map map) => RecipeStep(
        step: (map['step'] as num).toInt(),
        description: map['description'] as String,
      );
}

class RecipeIngredient {
  final int foodId;
  final num quantity;

  const RecipeIngredient({required this.foodId, required this.quantity});

  factory RecipeIngredient.fromMap(Map map) => RecipeIngredient(
        foodId: (map['food_id'] as num).toInt(),
        quantity: map['quantity'] as num,
      );
}

class RecipeModel {
  final String title;
  final String summary;
  final String chefReason;
  final String mealType;
  final String difficulty;
  final int preparationTimeMinutes;
  final int servings;
  final int estimatedCalories;
  final List<String> tips;
  final List<RecipeStep> steps;
  final List<RecipeIngredient> ingredients;

  const RecipeModel({
    required this.title,
    required this.summary,
    required this.chefReason,
    required this.mealType,
    required this.difficulty,
    required this.preparationTimeMinutes,
    required this.servings,
    required this.estimatedCalories,
    required this.tips,
    required this.steps,
    required this.ingredients,
  });

  static bool isRecipeMap(Map map) => map.containsKey('recipe_title');

  factory RecipeModel.fromMap(Map map) => RecipeModel(
        title: map['recipe_title'] as String? ?? '',
        summary: map['recipe_summary'] as String? ?? '',
        chefReason: map['chef_reason'] as String? ?? '',
        mealType: map['meal_type'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? '',
        preparationTimeMinutes:
            (map['preparation_time_minutes'] as num?)?.toInt() ?? 0,
        servings: (map['servings'] as num?)?.toInt() ?? 0,
        estimatedCalories: (map['estimated_calories'] as num?)?.toInt() ?? 0,
        tips: (map['tips'] as List?)?.map((e) => e.toString()).toList() ?? [],
        steps: (map['steps'] as List?)
                ?.map((e) => RecipeStep.fromMap(e as Map))
                .toList() ??
            [],
        ingredients: (map['ingredients_used'] as List?)
                ?.map((e) => RecipeIngredient.fromMap(e as Map))
                .toList() ??
            [],
      );
}
