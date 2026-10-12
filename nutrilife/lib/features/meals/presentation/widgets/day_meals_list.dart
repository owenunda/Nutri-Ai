import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/meal_card.dart';
import '../../data/models/day_meals.dart';
import '../../domain/meal_type.dart';

/// Las cuatro comidas de un día como tarjetas.
class DayMealsList extends StatelessWidget {
  final DayMeals day;
  final ValueChanged<MealGroup> onOpen;
  final ValueChanged<MealType>? onAdd;

  const DayMealsList({super.key, required this.day, required this.onOpen, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final type in MealType.values) ...[
          MealCard(
            emoji: type.emoji,
            title: type.label,
            description: day.of(type).summary,
            isLogged: !day.of(type).isEmpty,
            onTap: day.of(type).isEmpty ? null : () => onOpen(day.of(type)),
            onAdd: onAdd == null ? null : () => onAdd!(type),
          ),
          if (type != MealType.values.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
