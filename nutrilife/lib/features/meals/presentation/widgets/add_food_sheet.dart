import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../nutrition/data/models/food_model.dart';
import '../../data/meal_repository.dart';
import '../../domain/meal_type.dart';
import '../../domain/portions.dart';

Future<void> showAddFoodSheet(
  BuildContext context,
  FoodModel food, {
  MealType? initialType,
  MealRepository? repository,
  DateTime Function()? clock,
}) async {
  final now = (clock ?? DateTime.now)();
  final messenger = ScaffoldMessenger.of(context);
  final repo = repository ?? MealRepository();

  final result = await showModalBottomSheet<({int detailId, MealType type, int calories})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _AddFoodSheet(
      food: food,
      initialType: initialType ?? MealType.forTime(now),
      repository: repo,
      now: now,
    ),
  );
  if (result == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Agregado a ${result.type.label} · ${result.calories} kcal'),
      backgroundColor: AppTheme.primaryStart,
      action: SnackBarAction(
        label: 'Deshacer',
        textColor: Colors.white,
        onPressed: () async {
          try {
            await repo.deleteItem(result.detailId);
            MealLogState.instance.bump();
          } catch (_) {
            messenger.showSnackBar(const SnackBar(content: Text('No se pudo deshacer')));
          }
        },
      ),
    ));
}

class _AddFoodSheet extends StatefulWidget {
  final FoodModel food;
  final MealType initialType;
  final MealRepository repository;
  final DateTime now;

  const _AddFoodSheet({
    required this.food,
    required this.initialType,
    required this.repository,
    required this.now,
  });

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  static const _green = Color(0xFF0A6B3F);

  late MealType _type = widget.initialType;
  double _portions = 1;
  bool _saving = false;
  String? _error;

  int get _calories => caloriesFor(_portions, widget.food.caloriesPerUnit);

  String get _detail {
    final unit = _portions <= 1 ? 'porción' : 'porciones';
    return '${portionsLabel(_portions)} $unit · '
        '${quantityLabel(_portions, widget.food.baseUnit)} · $_calories kcal';
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
      final id = await widget.repository.addFood(
        foodId: widget.food.foodId,
        portions: _portions,
        type: _type,
        now: widget.now,
      );
      // Se avisa aquí (no en quien abre la hoja) para sincronizar aunque ya no esté montada.
      MealLogState.instance.bump();
      if (!mounted) return;
      Navigator.of(context).pop((detailId: id, type: _type, calories: _calories));
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
    return PopScope(
      canPop: !_saving,
      child: Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.food.name,
              style: const TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.food.caloriesPerUnit.round()} kcal por ${widget.food.baseUnit.toLowerCase()}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                    side: BorderSide(
                      color: _type == type ? _green : const Color(0xFFE2E8F0),
                    ),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Menos',
                  onTap: _portions > kMinPortions ? () => _step(-kPortionStep) : null,
                ),
                Expanded(
                  child: Text(
                    _detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C2F31),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Más',
                  onTap: _portions < kMaxPortions ? () => _step(kPortionStep) : null,
                ),
              ],
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
                child: Text('Agregar a ${_type.label}'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0A6B3F),
      ),
    );
  }
}
