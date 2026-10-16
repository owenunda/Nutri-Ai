import 'package:flutter/material.dart';
import '../../../../core/ads/ads_service.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chatbot/data/models/recipe_model.dart';
import '../../../nutrition/data/food_repository.dart';
import '../../../nutrition/data/models/food_model.dart';
import '../../data/meal_repository.dart';
import '../../domain/meal_type.dart';
import '../../domain/portions.dart';

/// Registra porciones de una receta del chat como sus ingredientes, en la
/// comida elegida. El backend guarda también la receta, para verla o borrarla
/// entera desde el historial en cualquier dispositivo.
Future<void> showRegisterRecipeSheet(
  BuildContext context,
  RecipeModel recipe, {
  MealRepository? repository,
  FoodRepository? foodRepository,
  DateTime Function()? clock,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  if (recipe.ingredients.isEmpty) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.mealsRegisterNoIngredients)));
    return;
  }

  final now = (clock ?? DateTime.now)();
  final repo = repository ?? MealRepository();

  final result = await showModalBottomSheet<({int recipeLogId, MealType type, int calories})>(
    context: context,
    sheetAnimationStyle: kSheetAnimation,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => _RegisterRecipeSheet(
      recipe: recipe,
      initialType: mealTypeOfRecipe(recipe) ?? MealType.forTime(now),
      repository: repo,
      foodRepository: foodRepository ?? FoodRepository(),
      now: now,
    ),
  );
  if (result == null) return;

  // Si toca intersticial, el aviso con "Deshacer" sale al cerrarlo, no debajo.
  await AdsService.instance.maybeShowAfterMealLog();

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.mealsRegisteredIn(result.type.label(l10n), result.calories)),
        backgroundColor: AppTheme.primaryStart,
        // Con un botón, Flutter lo deja fijo por defecto; aquí debe irse solo.
        persist: false,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.mealsUndo,
          textColor: Colors.white,
          onPressed: () async {
            try {
              // Borra la receta con todos sus ingredientes, de una vez.
              await repo.deleteRecipeLog(result.recipeLogId);
            } catch (_) {
              messenger.showSnackBar(SnackBar(content: Text(l10n.mealsUndoFailed)));
            } finally {
              MealLogState.instance.bump();
            }
          },
        ),
      ),
    );
}

/// "cena" → [MealType.dinner]. El chef escribe el tipo en español, sin
/// importar el idioma de la app.
MealType? mealTypeOfRecipe(RecipeModel recipe) {
  final value = recipe.mealType.trim().toLowerCase();
  for (final type in MealType.values) {
    if (type.recipeCode == value) return type;
  }
  return null;
}

/// Cantidad de cada ingrediente para [portions] porciones, en unidades base
/// del alimento (lo que guarda el backend). El chef da cantidades naturales
/// para toda la receta (300 g, 1 pera), así que se reparte por porción y se
/// convierte con la unidad base de [foods]. El backend guarda dos decimales y
/// exige más de 0.
List<({int foodId, double quantity})> ingredientsFor(
  RecipeModel recipe,
  double portions,
  Map<int, FoodModel> foods,
) {
  final servings = recipe.servings > 0 ? recipe.servings : 1;
  return [
    for (final i in recipe.ingredients)
      (
        foodId: i.foodId,
        quantity: (toBaseUnits(i.quantity * portions / servings, foods[i.foodId]?.baseUnit ?? '1') * 100)
                .round()
                .clamp(1, 1 << 31) /
            100,
      ),
  ];
}

/// Calorías reales de lo que se va a registrar, igual que las calcula el backend.
int caloriesOf(List<({int foodId, double quantity})> items, Map<int, FoodModel> foods) =>
    items.fold<double>(0, (sum, i) => sum + i.quantity * (foods[i.foodId]?.caloriesPerUnit ?? 0)).round();

class _RegisterRecipeSheet extends StatefulWidget {
  final RecipeModel recipe;
  final MealType initialType;
  final MealRepository repository;
  final FoodRepository foodRepository;
  final DateTime now;

  const _RegisterRecipeSheet({
    required this.recipe,
    required this.initialType,
    required this.repository,
    required this.foodRepository,
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

  /// Unidad base y calorías de cada ingrediente; sin ellas no se puede
  /// convertir la cantidad del chef, así que registrar espera a tenerlas.
  Map<int, FoodModel>? _foods;

  int get _servings => widget.recipe.servings > 0 ? widget.recipe.servings : 1;

  List<({int foodId, double quantity})> get _items => ingredientsFor(widget.recipe, _portions, _foods ?? const {});

  int get _calories => caloriesOf(_items, _foods ?? const {});

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _error = null);
    try {
      final foods = await widget.foodRepository.getFoods();
      if (!mounted) return;
      setState(() => _foods = {for (final f in foods) f.foodId: f});
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = context.l10n.mealsLoadFoodsError);
    }
  }

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
      final saved = await widget.repository.addRecipe(
        recipe: widget.recipe,
        portions: _portions,
        items: _items,
        type: _type,
        now: widget.now,
      );
      MealLogState.instance.bump();
      if (!mounted) return;
      Navigator.of(context).pop((recipeLogId: saved.recipeLogId, type: _type, calories: _calories));
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
    final l10n = context.l10n;
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
                Text(
                  l10n.mealsRegisterTitle,
                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w900),
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
                        label: Text(type.label(l10n)),
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
                        tooltip: l10n.mealsLessPortions,
                        icon: Icons.remove_rounded,
                        onPressed: _portions > kMinPortions ? () => _step(-kPortionStep) : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              portionsText(_portions, l10n),
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryStart,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _foods == null
                                  ? l10n.mealsCalculatingCalories(_servings)
                                  : l10n.mealsRecipeYield(_calories, _servings),
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
                        tooltip: l10n.mealsMorePortions,
                        icon: Icons.add_rounded,
                        onPressed: _portions < kMaxPortions ? () => _step(kPortionStep) : null,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  if (_foods == null)
                    TextButton(
                      onPressed: _loadFoods,
                      style: TextButton.styleFrom(foregroundColor: _green),
                      child: Text(l10n.commonRetry, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving || _foods == null ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    child: Text(l10n.mealsRegisterIn(_type.label(l10n))),
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
