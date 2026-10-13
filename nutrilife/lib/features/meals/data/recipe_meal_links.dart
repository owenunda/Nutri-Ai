import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../chatbot/data/models/recipe_model.dart';

/// Una receta registrada: qué ítems del día salieron de ella y cuántas porciones.
class RecipeLink {
  final RecipeModel recipe;
  final double portions;
  final List<int> detailIds;

  const RecipeLink({required this.recipe, required this.portions, required this.detailIds});

  Map<String, dynamic> toMap() => {
        'recipe': recipe.toMap(),
        'portions': portions,
        'detailIds': detailIds,
      };

  factory RecipeLink.fromMap(Map map) => RecipeLink(
        recipe: RecipeModel.fromMap(map['recipe'] as Map),
        portions: (map['portions'] as num).toDouble(),
        detailIds: (map['detailIds'] as List).map((e) => (e as num).toInt()).toList(),
      );
}

/// Recuerda en el teléfono de qué receta salió cada ingrediente registrado,
/// para poder volver a abrirla desde el historial. El backend solo guarda los
/// alimentos.
class RecipeMealLinks {
  static const _key = 'recipe_meal_links';
  static const _maxLinks = 200;

  const RecipeMealLinks();

  Future<List<RecipeLink>> _all(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map(RecipeLink.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(RecipeLink link) async {
    final prefs = await SharedPreferences.getInstance();
    final links = [...await _all(prefs), link];
    final kept = links.length > _maxLinks ? links.sublist(links.length - _maxLinks) : links;
    await prefs.setString(_key, jsonEncode(kept.map((l) => l.toMap()).toList()));
  }

  /// Receta de cada ítem registrado, por detailId.
  Future<Map<int, RecipeLink>> byDetailId() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final link in await _all(prefs))
        for (final id in link.detailIds) id: link,
    };
  }
}
