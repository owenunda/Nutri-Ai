import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/domain/meal_type.dart';
import '../../../meals/presentation/widgets/add_food_sheet.dart';
import '../../data/models/food_model.dart';
import '../../domain/food_units.dart';

/// Callback que el padre usa para registrar el alimento en la nevera real.
typedef AddToFridgeCallback = Future<bool> Function({
  required int foodId,
  required double quantity,
  required String unit,
});

/// Callback que el padre usa para registrar el consumo en la comida del día.
typedef ConsumeFoodCallback = Future<bool> Function({
  required int foodId,
  required double quantity,
  required MealType mealType,
});

/// Tarjeta de un alimento con sus calorías y el botón para registrarlo.
class FoodListTile extends StatelessWidget {
  final FoodModel food;

  /// Comida en la que se abre la hoja (al venir desde "Comidas de hoy").
  final MealType? mealType;

  /// Si viene de la pestaña "Comunes" y no hay mealType, al tocarlo se abre
  /// un menú rápido para meterlo a la nevera o registrarlo como consumido.
  final bool fromCommonTab;

  @visibleForTesting
  final MealRepository? repository;

  /// Si [fromCommonTab] es true, estos callbacks se usan para los flujos
  /// "agregar a mi nevera" y "lo consumí". Si el callback devuelve `true`,
  /// la hoja padre se ocupa de cerrar el sheet y mostrar el siguiente paso.
  final AddToFridgeCallback? onAddToFridge;
  final ConsumeFoodCallback? onConsume;

  const FoodListTile({
    super.key,
    required this.food,
    this.mealType,
    this.repository,
    this.fromCommonTab = false,
    this.onAddToFridge,
    this.onConsume,
  });

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

  Future<void> _showCommonFoodActions(BuildContext context) async {
    final result = await CommonFoodActionsSheet.show(
      context,
      food: food,
      emoji: _getFoodEmoji(food.name),
    );

    if (!context.mounted) return;
    if (result == null) return;

    if (result.action == CommonFoodAction.fridge) {
      await onAddToFridge?.call(
        foodId: food.foodId,
        quantity: result.quantity,
        unit: result.unit,
      );
    } else if (result.action == CommonFoodAction.consumed) {
      await onConsume?.call(
        foodId: food.foodId,
        quantity: result.quantity,
        mealType: result.mealType!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCommonQuickAction = mealType == null && fromCommonTab;

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
                  prettyUnitLabel(food.baseUnit),
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
            onTap: () {
              if (isCommonQuickAction) {
                _showCommonFoodActions(context);
              } else {
                showAddFoodSheet(
                  context,
                  food,
                  initialType: mealType,
                  repository: repository,
                );
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF0A6B3F),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CommonFoodAction { fridge, consumed }

class CommonFoodActionResult {
  final CommonFoodAction action;
  final double quantity;
  final String unit;
  final MealType? mealType;

  const CommonFoodActionResult.fridge({required this.quantity, required this.unit})
      : action = CommonFoodAction.fridge,
        mealType = null;

  const CommonFoodActionResult.consumed({required this.quantity, required this.mealType})
      : action = CommonFoodAction.consumed,
        unit = '';
}

/// Hoja modal reusable para que un alimento común se meta a la nevera o se
/// registre como consumido. Devuelve un [CommonFoodActionResult] o null.
class CommonFoodActionsSheet extends StatefulWidget {
  final FoodModel food;
  final String emoji;

  const CommonFoodActionsSheet({super.key, required this.food, required this.emoji});

  /// Helper para mostrarla y obtener el resultado.
  static Future<CommonFoodActionResult?> show(
    BuildContext context, {
    required FoodModel food,
    required String emoji,
  }) {
    return showModalBottomSheet<CommonFoodActionResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: CommonFoodActionsSheet(food: food, emoji: emoji),
        ),
      ),
    );
  }

  @override
  State<CommonFoodActionsSheet> createState() => _CommonFoodActionsSheetState();
}

class _CommonFoodActionsSheetState extends State<CommonFoodActionsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  String _unit = '1 UNIDAD';
  CommonFoodAction _intent = CommonFoodAction.fridge;
  MealType _mealType = MealType.forTime(DateTime.now());

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final qty = double.parse(_quantityController.text.replaceAll(',', '.'));
    if (_intent == CommonFoodAction.fridge) {
      Navigator.of(context).pop(
        CommonFoodActionResult.fridge(quantity: qty, unit: _unit),
      );
    } else {
      Navigator.of(context).pop(
        CommonFoodActionResult.consumed(quantity: qty, mealType: _mealType),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          color: Color(0xFF2C2F31),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.food.caloriesPerUnit.toInt()} kcal · ${widget.food.baseUnit}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Selector de intención: nevera vs consumido
            Row(
              children: [
                Expanded(
                  child: _IntentPill(
                    icon: Icons.kitchen_outlined,
                    label: 'A mi nevera',
                    selected: _intent == CommonFoodAction.fridge,
                    onTap: () => setState(() => _intent = CommonFoodAction.fridge),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _IntentPill(
                    icon: Icons.restaurant_outlined,
                    label: 'Lo consumí',
                    selected: _intent == CommonFoodAction.consumed,
                    onTap: () => setState(() => _intent = CommonFoodAction.consumed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa cantidad';
                      }
                      final v = double.tryParse(value.replaceAll(',', '.'));
                      if (v == null || v <= 0) return 'Debe ser > 0';
                      return null;
                    },
                  ),
                ),
                if (_intent == CommonFoodAction.fridge) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B)),
                      decoration: InputDecoration(
                        labelText: 'Unidad',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: const [
                        DropdownMenuItem(value: '1 UNIDAD', child: Text('1 unidad')),
                        DropdownMenuItem(value: '100 G', child: Text('100 g')),
                        DropdownMenuItem(value: '100 ML', child: Text('100 ml')),
                        DropdownMenuItem(value: '1 PORCIÓN', child: Text('1 porción')),
                        DropdownMenuItem(value: '1 TAZA', child: Text('1 taza')),
                      ],
                      onChanged: (v) => setState(() => _unit = v ?? '1 UNIDAD'),
                    ),
                  ),
                ],
              ],
            ),
            if (_intent == CommonFoodAction.consumed) ...[
              const SizedBox(height: 12),
              _MealTypePicker(
                selected: _mealType,
                onChanged: (t) => setState(() => _mealType = t),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C2F31),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _intent == CommonFoodAction.fridge
                          ? 'Guardar en mi nevera'
                          : 'Registrar consumo',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IntentPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0A6B3F) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF0A6B3F) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF2C2F31),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF2C2F31),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTypePicker extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  const _MealTypePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in MealType.values)
          ChoiceChip(
            label: Text('${t.emoji} ${t.label(context.l10n)}'),
            selected: t == selected,
            onSelected: (_) => onChanged(t),
            selectedColor: const Color(0xFFDFF6EA),
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide(
              color: t == selected ? const Color(0xFF0A6B3F) : const Color(0xFFE2E8F0),
            ),
            labelStyle: TextStyle(
              color: t == selected ? const Color(0xFF0A6B3F) : const Color(0xFF2C2F31),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
