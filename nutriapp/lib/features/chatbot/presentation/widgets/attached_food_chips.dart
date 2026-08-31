import 'package:flutter/material.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';

/// Etiquetas de los alimentos adjuntos a un mensaje.
///
/// Van sobre el verde de la burbuja del usuario, así que el contraste se
/// resuelve con blanco translúcido en vez de un color propio.
class AttachedFoodChips extends StatelessWidget {
  final List<FridgeItemModel> foods;

  const AttachedFoodChips({super.key, required this.foods});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: foods.map((food) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                _label(food),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _label(FridgeItemModel food) {
  if (food.quantity <= 0) return food.name;

  final quantity = food.quantity % 1 == 0
      ? food.quantity.toInt().toString()
      : food.quantity.toString();

  return '${food.name} · $quantity ${food.unit}';
}
