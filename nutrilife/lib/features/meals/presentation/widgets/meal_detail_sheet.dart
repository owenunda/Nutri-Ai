import 'package:flutter/material.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chatbot/presentation/widgets/recipe_card_widget.dart';
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
    sheetAnimationStyle: kSheetAnimation,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
          child: _MealDetail(group: group, repository: repo),
        ),
      ),
    ),
  );
}

class _MealDetail extends StatelessWidget {
  final MealGroup group;
  final MealRepository repository;

  const _MealDetail({required this.group, required this.repository});

  @override
  Widget build(BuildContext context) {
    // Ítems agrupados por la receta de la que salieron, en orden de aparición.
    // Las recetas vienen del backend, así que se ven igual en cualquier dispositivo.
    final byRecipe = <LoggedRecipe, List<MealItem>>{};
    final loose = <MealItem>[];
    for (final item in group.items) {
      final recipe = group.recipeOf(item);
      if (recipe == null) {
        loose.add(item);
      } else {
        byRecipe.putIfAbsent(recipe, () => []).add(item);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${group.type.label} · ${group.totalCalories} kcal',
          style: const TextStyle(color: Color(0xFF2C2F31), fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final entry in byRecipe.entries) ...[
          _RecipeHeader(logged: entry.key, items: entry.value, repository: repository),
          // Los ingredientes de una receta solo se borran con la receta entera.
          for (final item in entry.value)
            _ItemTile(
              item: item,
              subtitle: ingredientAmountLabel(item.quantity, item.baseUnit),
              repository: repository,
              deletable: false,
            ),
          const SizedBox(height: 8),
        ],
        if (byRecipe.isNotEmpty && loose.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'OTROS ALIMENTOS',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
        for (final item in loose)
          _ItemTile(
            item: item,
            subtitle: mealItemLabel(item.quantity, item.baseUnit),
            repository: repository,
          ),
      ],
    );
  }
}

class _RecipeHeader extends StatelessWidget {
  final LoggedRecipe logged;
  final List<MealItem> items;
  final MealRepository repository;

  const _RecipeHeader({required this.logged, required this.items, required this.repository});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar receta?'),
        content: Text('Se quitará "${logged.title}" con sus ${items.length} ingredientes de esta comida.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // El backend borra la receta y sus ingredientes en una transacción.
      await repository.deleteRecipeLog(logged.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      MealLogState.instance.bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = items.fold<int>(0, (sum, i) => sum + i.calories);
    final unit = logged.portions <= 1 ? 'porción' : 'porciones';
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryStart, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logged.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${portionsLabel(logged.portions)} $unit · $calories kcal',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _delete(context),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Borrar receta', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => showRecipeInfoSheet(context, logged.recipe),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryStart),
                child: const Text('Ver receta', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final MealItem item;
  final String subtitle;
  final MealRepository repository;
  final bool deletable;

  const _ItemTile({required this.item, required this.subtitle, required this.repository, this.deletable = true});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${item.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w800)),
          if (!deletable) const SizedBox(width: 12),
          if (deletable)
            IconButton(
              tooltip: 'Borrar ${item.name}',
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () async {
                try {
                  await repository.deleteItem(item.detailId);
                  MealLogState.instance.bump();
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
            ),
        ],
      ),
    );
  }
}
