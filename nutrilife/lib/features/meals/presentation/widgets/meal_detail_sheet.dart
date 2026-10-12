import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../data/meal_repository.dart';
import '../../data/models/day_meals.dart';
import '../../domain/portions.dart';

Future<void> showMealDetailSheet(
  BuildContext context,
  MealGroup group, {
  MealRepository? repository,
}) {
  final repo = repository ?? MealRepository();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.type.label} · ${group.totalCalories} kcal',
              style: const TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in group.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${portionsLabel(item.quantity)} ${item.quantity <= 1 ? 'porción' : 'porciones'} · '
                  '${quantityLabel(item.quantity, item.baseUnit)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${item.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      tooltip: 'Borrar ${item.name}',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        try {
                          await repo.deleteItem(item.detailId);
                          MealLogState.instance.bump();
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        } catch (e) {
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
