import 'package:flutter/material.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chatbot/data/models/recipe_model.dart';
import '../../data/meal_repository.dart';
import '../../data/recipe_meal_links.dart';
import '../../domain/meal_type.dart';
import '../../domain/portions.dart';

/// Registra porciones de una receta del chat como sus ingredientes, en la
/// comida elegida, y recuerda la receta para verla desde el historial.
Future<void> showRegisterRecipeSheet(
  BuildContext context,
  RecipeModel recipe, {
  MealRepository? repository,
  RecipeMealLinks links = const RecipeMealLinks(),
  DateTime Function()? clock,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (recipe.ingredients.isEmpty) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Esta receta no trae ingredientes para registrar')));
    return;
  }

  final now = (clock ?? DateTime.now)();
  final repo = repository ?? MealRepository();

  final result = await showModalBottomSheet<({List<int> detailIds, MealType type, int calories})>(
    context: context,
    sheetAnimationStyle: kSheetAnimation,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => _RegisterRecipeSheet(
      recipe: recipe,
      initialType: mealTypeOfRecipe(recipe) ?? MealType.forTime(now),
      repository: repo,
      links: links,
      now: now,
    ),
  );
  if (result == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Registrado en ${result.type.label} · ≈${result.calories} kcal'),
        backgroundColor: AppTheme.primaryStart,
        // Con un botón, Flutter lo deja fijo por defecto; aquí debe irse solo.
        persist: false,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () async {
            try {
              for (final id in result.detailIds) {
                await repo.deleteItem(id);
              }
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text('No se pudo deshacer')));
            } finally {
              MealLogState.instance.bump();
            }
          },
        ),
      ),
    );
}

/// "cena" → [MealType.dinner]. El chef escribe el tipo en español.
MealType? mealTypeOfRecipe(RecipeModel recipe) {
  final value = recipe.mealType.trim().toLowerCase();
  for (final type in MealType.values) {
    if (type.label.toLowerCase() == value) return type;
  }
  return null;
}

/// Cantidad de cada ingrediente para [portions] porciones. El backend guarda
/// dos decimales y exige más de 0.
List<({int foodId, double quantity})> ingredientsFor(RecipeModel recipe, double portions) {
  final servings = recipe.servings > 0 ? recipe.servings : 1;
  return [
    for (final i in recipe.ingredients)
      (foodId: i.foodId, quantity: ((i.quantity * portions / servings) * 100).round().clamp(1, 1 << 31) / 100),
  ];
}

class _RegisterRecipeSheet extends StatefulWidget {
  final RecipeModel recipe;
  final MealType initialType;
  final MealRepository repository;
  final RecipeMealLinks links;
  final DateTime now;

  const _RegisterRecipeSheet({
    required this.recipe,
    required this.initialType,
    required this.repository,
    required this.links,
    required this.now,
  });

  @override
  State<_RegisterRecipeSheet> createState() => _RegisterRecipeSheetState();
}

class _RegisterRecipeSheetState extends State<_RegisterRecipeSheet> {
  static const _green = Color(0xFF0A6B3F);

  late MealType _type = widget.initialType;
  double _portions = 1;
  bool _saving = false;
  String? _error;

  int get _servings => widget.recipe.servings > 0 ? widget.recipe.servings : 1;

  /// Estimación del chef; el total real lo calcula el backend con los alimentos.
  int get _calories => (widget.recipe.estimatedCalories / _servings * _portions).round();

  void _step(double delta) {
    setState(() {
      _portions = (_portions + delta).clamp(kMinPortions, kMaxPortions);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ids = await widget.repository.addFoods(
        items: ingredientsFor(widget.recipe, _portions),
        type: _type,
        now: widget.now,
      );
      // Si no se pudo guardar el vínculo, la comida igual quedó registrada.
      try {
        await widget.links.save(RecipeLink(recipe: widget.recipe, portions: _portions, detailIds: ids));
      } catch (_) {}
      MealLogState.instance.bump();
      if (!mounted) return;
      Navigator.of(context).pop((detailIds: ids, type: _type, calories: _calories));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = _portions <= 1 ? 'porción' : 'porciones';
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          // Si aparece un error, la hoja crece suave en vez de saltar.
          child: AnimatedSize(
            duration: kResizeDuration,
            curve: kResizeCurve,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registrar comida',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF747779), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in MealType.values)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                        selectedColor: const Color(0xFFDCFCE7),
                        labelStyle: TextStyle(
                          color: _type == type ? _green : const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(color: _type == type ? _green : const Color(0xFFE2E8F0)),
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      _StepButton(
                        tooltip: 'Menos porciones',
                        icon: Icons.remove_rounded,
                        onPressed: _portions > kMinPortions ? () => _step(-kPortionStep) : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${portionsLabel(_portions)} $unit',
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryStart,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '≈$_calories kcal · la receta rinde $_servings',
                              style: const TextStyle(
                                color: Color(0xFF747779),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StepButton(
                        tooltip: 'Más porciones',
                        icon: Icons.add_rounded,
                        onPressed: _portions < kMaxPortions ? () => _step(kPortionStep) : null,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    child: Text('Registrar en ${_type.label}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.tooltip, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryStart,
        fixedSize: const Size(52, 52),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}
