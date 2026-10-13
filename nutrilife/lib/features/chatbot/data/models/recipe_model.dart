class RecipeStep {
  final int step;
  final String description;

  const RecipeStep({required this.step, required this.description});

  factory RecipeStep.fromMap(Map map, {int fallbackStep = 0}) => RecipeStep(
        step: (map['step'] as num?)?.toInt() ?? fallbackStep,
        description: map['description'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'step': step, 'description': description};
}

class RecipeIngredient {
  final int foodId;
  final num quantity;

  const RecipeIngredient({required this.foodId, required this.quantity});

  factory RecipeIngredient.fromMap(Map map) => RecipeIngredient(
        foodId: (map['food_id'] as num).toInt(),
        quantity: map['quantity'] as num,
      );

  Map<String, dynamic> toMap() => {'food_id': foodId, 'quantity': quantity};
}

class YoutubeVideoModel {
  final String videoId;
  final String title;
  final String channel;
  final String thumbnailUrl;
  final String url;

  const YoutubeVideoModel({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnailUrl,
    required this.url,
  });

  factory YoutubeVideoModel.fromMap(Map map) => YoutubeVideoModel(
        videoId: map['video_id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        channel: map['channel'] as String? ?? '',
        thumbnailUrl: map['thumbnail'] as String? ?? '',
        url: map['url'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'video_id': videoId,
        'title': title,
        'channel': channel,
        'thumbnail': thumbnailUrl,
        'url': url,
      };
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
  final YoutubeVideoModel? youtubeVideo;

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
    this.youtubeVideo,
  });

  factory RecipeModel.fromMap(Map map, {YoutubeVideoModel? youtube}) =>
      RecipeModel(
        title: map['recipe_title'] as String? ?? map['title'] as String? ?? '',
        summary: map['recipe_summary'] as String? ?? map['summary'] as String? ?? '',
        chefReason: map['chef_reason'] as String? ?? '',
        mealType: map['meal_type'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? '',
        preparationTimeMinutes:
            (map['preparation_time_minutes'] as num?)?.toInt() ?? 0,
        servings: (map['servings'] as num?)?.toInt() ?? 0,
        estimatedCalories: (map['estimated_calories'] as num?)?.toInt() ?? 0,
        tips: (map['tips'] as List?)?.map((e) => e.toString()).toList() ?? [],
        steps: (map['steps'] as List?)
                ?.whereType<Map>()
                .toList()
                .asMap()
                .entries
                .map((e) => RecipeStep.fromMap(e.value, fallbackStep: e.key + 1))
                .toList() ??
            [],
        ingredients: (map['ingredients_used'] as List?)
                ?.whereType<Map>()
                .map(RecipeIngredient.fromMap)
                .toList() ??
            [],
        youtubeVideo: youtube ??
            (map['youtube'] is Map ? YoutubeVideoModel.fromMap(map['youtube'] as Map) : null),
      );

  /// Inverso de [RecipeModel.fromMap], para guardarla en el teléfono.
  Map<String, dynamic> toMap() => {
        'recipe_title': title,
        'recipe_summary': summary,
        'chef_reason': chefReason,
        'meal_type': mealType,
        'difficulty': difficulty,
        'preparation_time_minutes': preparationTimeMinutes,
        'servings': servings,
        'estimated_calories': estimatedCalories,
        'tips': tips,
        'steps': steps.map((s) => s.toMap()).toList(),
        'ingredients_used': ingredients.map((i) => i.toMap()).toList(),
        if (youtubeVideo != null) 'youtube': youtubeVideo!.toMap(),
      };
}
