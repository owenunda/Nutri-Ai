import 'package:flutter/material.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/domain/meal_type.dart';
import '../../../meals/presentation/widgets/add_food_sheet.dart';
import '../../data/models/food_model.dart';

/// Tarjeta de un alimento con sus calorías y el botón para registrarlo.
class FoodListTile extends StatelessWidget {
  final FoodModel food;

  /// Comida en la que se abre la hoja (al venir desde "Comidas de hoy").
  final MealType? mealType;

  @visibleForTesting
  final MealRepository? repository;

  const FoodListTile({super.key, required this.food, this.mealType, this.repository});

  String _getFoodEmoji(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('apple') || lowerName.contains('manzana')) return '🍎';
    if (lowerName.contains('chicken') || lowerName.contains('pollo')) return '🍗';
    if (lowerName.contains('rice') || lowerName.contains('arroz')) return '🍚';
    if (lowerName.contains('avocado') || lowerName.contains('aguacate')) return '🥑';
    if (lowerName.contains('banana') || lowerName.contains('plátano') || lowerName.contains('platano')) return '🍌';
    if (lowerName.contains('meat') || lowerName.contains('carne')) return '🥩';
    if (lowerName.contains('egg') || lowerName.contains('huevo')) return '🥚';
    if (lowerName.contains('milk') || lowerName.contains('leche')) return '🥛';
    if (lowerName.contains('bread') || lowerName.contains('pan')) return '🍞';
    if (lowerName.contains('fish') || lowerName.contains('pescado')) return '🐟';
    if (lowerName.contains('salad') || lowerName.contains('ensalada')) return '🥗';
    return '🍲';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(_getFoodEmoji(food.name), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    color: Color(0xFF2C2F31),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.baseUnit.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${food.caloriesPerUnit.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'KCAL',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => showAddFoodSheet(
              context,
              food,
              initialType: mealType,
              repository: repository,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF0A6B3F), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
