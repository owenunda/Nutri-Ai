import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
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
            title: type.label(context.l10n),
            description: day.of(type).summary(context.l10n),
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
