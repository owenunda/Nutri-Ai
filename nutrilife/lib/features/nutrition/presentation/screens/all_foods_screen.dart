import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../meals/domain/meal_type.dart';
import '../../data/food_repository.dart';
import '../../data/fridge_repository.dart';
import '../../data/models/food_model.dart';
import '../../data/models/fridge_item_model.dart';
import '../../domain/food_units.dart';
import '../controllers/foods_view_model.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_field.dart';

/// Lista completa de alimentos con su propio buscador. Modos:
/// - [showFridge] true: muestra los ítems reales de la nevera.
/// - [mealType] != null: la acción de los ítems es registrar comida (modo
///   "Agregar a {mealType}").
class AllFoodsScreen extends StatefulWidget {
  final List<FoodModel>? foods;
  final MealType? mealType;
  final FoodRepository? foodRepository;
  final FridgeRepository? fridgeRepository;
  final String? title;

  /// Si es true, en vez del catálogo se listan los ítems reales de la nevera
  /// (fridge_items) y se ocultan los controles de catálogo.
  final bool showFridge;

  @visibleForTesting
  final FoodsViewModel? viewModel;

  const AllFoodsScreen({
    super.key,
    this.foods,
    this.mealType,
    this.foodRepository,
    this.fridgeRepository,
    this.title,
    this.showFridge = false,
    this.viewModel,
  });

  @override
  State<AllFoodsScreen> createState() => _AllFoodsScreenState();
}

class _AllFoodsScreenState extends State<AllFoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final FridgeRepository _fridgeRepository;
  List<FoodModel> _all = const [];
  List<FoodModel> _visible = const [];
  List<FridgeItemModel> _fridgeItems = const [];
  List<FridgeItemModel> _visibleFridge = const [];
  final Set<int> _busyFridgeItemIds = {};
  bool _loading = false;
  String? _error;

  String _emojiFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('apple') || lower.contains('manzana')) return '🍎';
    if (lower.contains('chicken') || lower.contains('pollo')) return '🍗';
    if (lower.contains('rice') || lower.contains('arroz')) return '🍚';
    if (lower.contains('avocado') || lower.contains('aguacate')) return '🥑';
    if (lower.contains('banana') ||
        lower.contains('plátano') ||
        lower.contains('platano')) {
      return '🍌';
    }
    if (lower.contains('meat') || lower.contains('carne')) return '🥩';
    if (lower.contains('egg') || lower.contains('huevo')) return '🥚';
    if (lower.contains('milk') || lower.contains('leche')) return '🥛';
    if (lower.contains('bread') || lower.contains('pan')) return '🍞';
    if (lower.contains('fish') || lower.contains('pescado')) return '🐟';
    if (lower.contains('salad') || lower.contains('ensalada')) return '🥗';
    return '🍲';
  }

  @override
  void initState() {
    super.initState();
    _fridgeRepository = widget.fridgeRepository ?? FridgeRepository();
    _searchController.addListener(() {
      final query = _searchController.text;
      setState(() {
        _visible = FoodsViewModel.filterFoods(_all, query);
        _visibleFridge = _fridgeItems
            .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    });
    if (widget.foods != null) {
      _all = widget.foods!;
      _visible = widget.foods!;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.showFridge) {
        final items = await _fridgeRepository.getFridgeItems();
        if (!mounted) return;
        setState(() {
          _fridgeItems = items;
          _visibleFridge = items;
          _loading = false;
        });
        return;
      }
      final foods = await (widget.foodRepository ?? FoodRepository())
          .getFoods();
      if (!mounted) return;
      setState(() {
        _all = foods;
        _visible = FoodsViewModel.filterFoods(foods, _searchController.text);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFridge = widget.showFridge;
    final count = showFridge ? _visibleFridge.length : _visible.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
        title: Text(
          widget.title ??
              (widget.mealType != null
                  ? context.l10n.homeAddToMeal(widget.mealType!.label(context.l10n))
                  : (showFridge ? 'Mi nevera' : 'Todos los alimentos')),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: FoodSearchField(controller: _searchController),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 24, 12),
            child: Text(
              '$count ${count == 1 ? (showFridge ? 'ítem' : 'alimento') : (showFridge ? 'ítems' : 'alimentos')}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : (showFridge ? _buildFridgeList() : _buildCommonList()),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonList() {
    // Modo "Agregar a {mealType}" (venido de "Comidas de hoy") usa el flujo
    // clásico de selección de comida. En cualquier otro modo (ej. "Ver todos"
    // desde la pestaña Comunes), la acción por defecto es "agregar a mi
    // nevera / lo consumí" — la del sheet contextual.
    final isAddToMeal = widget.mealType != null;
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => FoodListTile(
        food: _visible[index],
        mealType: isAddToMeal ? widget.mealType : null,
        fromCommonTab: !isAddToMeal,
      ),
    );
  }

  Widget _buildFridgeList() {
    if (_visibleFridge.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Tu nevera está vacía. Agrega alimentos desde "Entrada manual" o desde la pestaña Comunes.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _visibleFridge.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _visibleFridge[index];
        final isBusy = _busyFridgeItemIds.contains(item.fridgeItemId);
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                child: Text(
                  _emojiFor(item.name),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF2C2F31),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatQuantityWithUnit(item.quantity, item.unit),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Editar cantidad de ${item.name}',
                onPressed: isBusy || !item.isFromFridge
                    ? null
                    : () => _manageFridgeItem(item),
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune_rounded, color: Color(0xFF0A6B3F)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _manageFridgeItem(FridgeItemModel item) async {
    final change = await showModalBottomSheet<_FridgeItemChange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _FridgeItemManagementSheet(item: item),
        ),
      ),
    );
    if (!mounted || change == null) return;

    var shouldDelete = change.action == _FridgeChangeAction.remove;
    final quantity = switch (change.action) {
      _FridgeChangeAction.set => change.amount,
      _FridgeChangeAction.add => item.quantity + change.amount,
      _FridgeChangeAction.subtract => item.quantity - change.amount,
      _FridgeChangeAction.remove => 0.0,
    };

    if (change.action == _FridgeChangeAction.subtract && quantity <= 0) {
      shouldDelete = await _confirmFridgeItemRemoval(item);
      if (!shouldDelete) return;
    } else if (shouldDelete) {
      shouldDelete = await _confirmFridgeItemRemoval(item);
      if (!shouldDelete) return;
    }

    setState(() => _busyFridgeItemIds.add(item.fridgeItemId));
    try {
      if (shouldDelete) {
        await _fridgeRepository.deleteItem(fridgeItemId: item.fridgeItemId);
        if (!mounted) return;
        setState(() {
          _fridgeItems.removeWhere(
            (current) => current.fridgeItemId == item.fridgeItemId,
          );
          _visibleFridge.removeWhere(
            (current) => current.fridgeItemId == item.fridgeItemId,
          );
        });
        _showFridgeMessage('${item.name} se quitó de tu nevera');
      } else {
        await _fridgeRepository.updateItem(
          fridgeItemId: item.fridgeItemId,
          quantity: quantity,
        );
        if (!mounted) return;
        final updatedItem = FridgeItemModel(
          fridgeItemId: item.fridgeItemId,
          foodId: item.foodId,
          name: item.name,
          quantity: quantity,
          unit: item.unit,
          caloriesPerUnit: item.caloriesPerUnit,
          baseUnit: item.baseUnit,
        );
        setState(() {
          _replaceFridgeItem(_fridgeItems, updatedItem);
          _replaceFridgeItem(_visibleFridge, updatedItem);
        });
        _showFridgeMessage('Cantidad de ${item.name} actualizada');
      }
    } catch (error) {
      if (mounted) {
        _showFridgeMessage(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyFridgeItemIds.remove(item.fridgeItemId));
      }
    }
  }

  void _replaceFridgeItem(
    List<FridgeItemModel> items,
    FridgeItemModel replacement,
  ) {
    final index = items.indexWhere(
      (item) => item.fridgeItemId == replacement.fridgeItemId,
    );
    if (index >= 0) items[index] = replacement;
  }

  Future<bool> _confirmFridgeItemRemoval(FridgeItemModel item) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Quitar alimento'),
            content: Text(
              '¿Quieres quitar ${item.name} de tu nevera? Ya no aparecerá entre tus alimentos disponibles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Quitar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showFridgeMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF0A6B3F),
        ),
      );
  }
}

enum _FridgeChangeAction { set, add, subtract, remove }

class _FridgeItemChange {
  const _FridgeItemChange(this.action, [this.amount = 0]);

  final _FridgeChangeAction action;
  final double amount;
}

class _FridgeItemManagementSheet extends StatefulWidget {
  const _FridgeItemManagementSheet({required this.item});

  final FridgeItemModel item;

  @override
  State<_FridgeItemManagementSheet> createState() =>
      _FridgeItemManagementSheetState();
}

class _FridgeItemManagementSheetState
    extends State<_FridgeItemManagementSheet> {
  late final TextEditingController _adjustmentController;
  late final TextEditingController _exactQuantityController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _adjustmentController = TextEditingController(text: '1');
    _exactQuantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _adjustmentController.dispose();
    _exactQuantityController.dispose();
    super.dispose();
  }

  double? _readAmount(TextEditingController controller) {
    final amount = double.tryParse(
      controller.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _validationMessage = 'Ingresa una cantidad mayor que 0');
      return null;
    }
    setState(() => _validationMessage = null);
    return amount;
  }

  void _submit(
    _FridgeChangeAction action,
    TextEditingController controller,
  ) {
    final amount = _readAmount(controller);
    if (amount == null) return;
    if (action == _FridgeChangeAction.subtract &&
        amount > widget.item.quantity) {
      setState(
        () => _validationMessage =
            'No puedes descontar más de lo que tienes (${widget.item.quantity}).',
      );
      return;
    }
    Navigator.of(context).pop(_FridgeItemChange(action, amount));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Disponible: ${formatQuantityWithUnit(item.quantity, item.unit)}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('fridge-adjust-quantity'),
              controller: _adjustmentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                if (_validationMessage != null) {
                  setState(() => _validationMessage = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Cantidad para sumar o descontar (${item.unit})',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorText: _validationMessage,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _submit(
                      _FridgeChangeAction.subtract,
                      _adjustmentController,
                    ),
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Descontar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _submit(
                      _FridgeChangeAction.add,
                      _adjustmentController,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Aumentar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('fridge-exact-quantity'),
              controller: _exactQuantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                if (_validationMessage != null) {
                  setState(() => _validationMessage = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Cantidad total nueva (${item.unit})',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorText: _validationMessage,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => _submit(
                _FridgeChangeAction.set,
                _exactQuantityController,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B3F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar cantidad exacta'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(const _FridgeItemChange(_FridgeChangeAction.remove)),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Quitar de la nevera'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
