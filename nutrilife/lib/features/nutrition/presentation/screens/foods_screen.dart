import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/domain/meal_type.dart';
import '../../data/food_repository.dart';
import '../../data/models/food_model.dart';
import '../../data/models/fridge_item_model.dart';
import '../../domain/food_units.dart';
import '../controllers/foods_view_model.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_field.dart';
import 'all_foods_screen.dart';

class FoodsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  @visibleForTesting
  final FoodRepository? foodRepository;

  @visibleForTesting
  final MealRepository? mealRepository;

  const FoodsScreen({
    super.key,
    this.user,
    this.foodRepository,
    this.mealRepository,
  });

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  late final FoodsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// En la vista normal solo se ven unos pocos; el resto está en "Ver todo".
  static const _previewCount = 5;

  /// null hasta que el usuario elige: abre en "Mis alimentos" si tiene.
  int? _tab;
  bool _showAllCommon = false;
  final GlobalKey<_BulkAddComunesSectionState> _commonSelectionKey =
      GlobalKey<_BulkAddComunesSectionState>();
  Set<int> _selectedCommonFoodIds = {};
  bool _bulkLoading = false;

  List<FoodModel> get _common =>
      _viewModel.foods.where((f) => f.isGlobal).toList();
  bool get _showMine =>
      (_tab ?? (_viewModel.fridgeItems.isNotEmpty ? 0 : 1)) == 0;

  /// Buscando, la tarjeta y el consejo se esconden para que el teclado no
  /// tape los resultados.
  bool get _isSearching =>
      _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _viewModel = FoodsViewModel(
      foodRepository: widget.foodRepository,
      mealRepository: widget.mealRepository,
    );
    _searchFocusNode.addListener(() {
      setState(() {});
      if (_isSearching) _clearCommonSelection();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.refreshAll();
    });
    _searchController.addListener(() {
      _viewModel.searchFoods(_searchController.text);
      if (_searchController.text.isNotEmpty) _clearCommonSelection();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showAddCustomFoodSheet({
    _FoodEntryIntent intent = _FoodEntryIntent.inFridge,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var unit = kDefaultFoodUnit;
    MealType mealType = MealType.forTime(DateTime.now());
    FoodModel? selectedExistingFood;

    final isInFridge = intent == _FoodEntryIntent.inFridge;
    final title = isInFridge ? 'Agregar a mi nevera' : 'Registrar consumido';
    final subtitle = isInFridge
        ? 'Lo guardarás en tu nevera para que la IA pueda sugerirlo al chatear.'
        : 'Se registrará como consumido en la comida que elijas para que el conteo de calorías sea correcto.';

    showModalBottomSheet(
      context: context,
      sheetAnimationStyle: kSheetAnimation,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF6EA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isInFridge
                                ? Icons.kitchen_outlined
                                : Icons.restaurant_outlined,
                            color: const Color(0xFF0A6B3F),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF2C2F31),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del alimento',
                        hintText: 'Ej. Banana',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final existingFood = selectedExistingFood;
                        if (existingFood != null &&
                            value.trim().toLowerCase() !=
                                existingFood.name.toLowerCase()) {
                          setSheetState(() => selectedExistingFood = null);
                        }
                      },
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nameController,
                      builder: (context, value, _) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty || selectedExistingFood != null) {
                          return const SizedBox.shrink();
                        }
                        final matches =
                            _viewModel.allFoods
                                .where(
                                  (food) =>
                                      food.name.toLowerCase().contains(query),
                                )
                                .toList()
                              ..sort((a, b) {
                                final aExact = a.name.toLowerCase() == query;
                                final bExact = b.name.toLowerCase() == query;
                                if (aExact != bExact) return aExact ? -1 : 1;
                                final aStartsWith = a.name
                                    .toLowerCase()
                                    .startsWith(query);
                                final bStartsWith = b.name
                                    .toLowerCase()
                                    .startsWith(query);
                                if (aStartsWith != bStartsWith) {
                                  return aStartsWith ? -1 : 1;
                                }
                                return a.name.compareTo(b.name);
                              });
                        if (matches.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ya existe un alimento parecido. Elige uno para usarlo:',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final food in matches.take(4))
                                ListTile(
                                  key: ValueKey('existing-food-${food.foodId}'),
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  tileColor: const Color(0xFFF1F5F9),
                                  title: Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${food.caloriesPerUnit.toStringAsFixed(0)} kcal · ${prettyUnitLabel(food.baseUnit)}',
                                  ),
                                  trailing: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: Color(0xFF0A6B3F),
                                  ),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedExistingFood = food;
                                      nameController.text = food.name;
                                      unit = food.baseUnit;
                                    });
                                    FocusScope.of(sheetContext).unfocus();
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (selectedExistingFood != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        key: const ValueKey('selected-existing-food'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF6EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF0A6B3F),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Usar ${selectedExistingFood!.name}',
                                style: const TextStyle(
                                  color: Color(0xFF0A6B3F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setSheetState(
                                () => selectedExistingFood = null,
                              ),
                              child: const Text('Cambiar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (selectedExistingFood == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: caloriesController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Calorías (Kcal)',
                                hintText: 'Ej. 105',
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa calorías';
                                }
                                final numVal = double.tryParse(value);
                                if (numVal == null || numVal <= 0) {
                                  return 'Debe ser > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey('unit-field'),
                              initialValue: unit,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFF64748B),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Porción',
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              items: [
                                for (final option in kFoodUnits)
                                  DropdownMenuItem(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                              ],
                              onChanged: (value) =>
                                  unit = value ?? kDefaultFoodUnit,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const ValueKey('manual-food-quantity'),
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: isInFridge
                            ? 'Cantidad que tienes'
                            : 'Cantidad consumida',
                        hintText: '1',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                    if (!isInFridge) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Comida del día',
                        style: TextStyle(
                          color: Color(0xFF2C2F31),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in MealType.values)
                            ChoiceChip(
                              key: ValueKey('meal-type-${t.apiValue}'),
                              label: Text('${t.emoji} ${t.label(sheetContext.l10n)}'),
                              selected: t == mealType,
                              onSelected: (_) =>
                                  setSheetState(() => mealType = t),
                              selectedColor: const Color(0xFFDFF6EA),
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: t == mealType
                                    ? const Color(0xFF0A6B3F)
                                    : const Color(0xFFE2E8F0),
                              ),
                              labelStyle: TextStyle(
                                color: t == mealType
                                    ? const Color(0xFF0A6B3F)
                                    : const Color(0xFF2C2F31),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return PrimaryButton(
                          textButton: _viewModel.isLoading
                              ? 'Guardando...'
                              : (isInFridge
                                    ? 'Guardar en nevera'
                                    : 'Registrar consumo'),
                          width: double.infinity,
                          icon: Icons.check,
                          iconSize: 18,
                          textSize: 14,
                          spacing: 6,
                          onPressed: _viewModel.isLoading
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    final name = nameController.text.trim();
                                    final quantity = double.parse(
                                      quantityController.text.replaceAll(
                                        ',',
                                        '.',
                                      ),
                                    );

                                    var foodId =
                                        selectedExistingFood?.foodId ?? 0;
                                    if (selectedExistingFood == null) {
                                      final calories = double.parse(
                                        caloriesController.text,
                                      );
                                      final foodCreated = await _viewModel
                                          .addCustomFood(
                                            name: name,
                                            calories: calories,
                                            baseUnit: unit,
                                          );
                                      if (!sheetContext.mounted) return;
                                      if (!foodCreated) {
                                        ScaffoldMessenger.of(
                                          sheetContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _viewModel.errorMessage ??
                                                  'Error',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }
                                      foodId = _viewModel.findFoodIdByName(
                                        name,
                                      );
                                    }

                                    if (foodId == 0) {
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(
                                          sheetContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se pudo obtener el identificador del alimento. Inténtalo de nuevo.',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final secondOk = isInFridge
                                        ? await _viewModel.addToFridge(
                                            foodId: foodId,
                                            quantity: quantity,
                                            unit: unit,
                                          )
                                        : await _viewModel.consumeFood(
                                            foodId: foodId,
                                            quantity: quantity,
                                            mealType: mealType,
                                          );

                                    if (!sheetContext.mounted) return;
                                    if (secondOk) {
                                      Navigator.pop(sheetContext);
                                      await _viewModel.fetchFoods();
                                      if (sheetContext.mounted) {
                                        setState(() {});
                                        _showPostAddSheet(
                                          isInFridge: isInFridge,
                                        );
                                      }
                                    } else {
                                      // Mantenemos la hoja abierta para que el
                                      // usuario pueda reintentar tras ver el error.
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _viewModel.errorMessage ??
                                                'No se pudo completar el registro. Inténtalo de nuevo.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPostAddSheet({required bool isInFridge}) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 16),
              const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0A6B3F),
                  size: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Listo!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isInFridge
                    ? 'Tu alimento ya está en la nevera.'
                    : 'Tu consumo quedó registrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _showAddCustomFoodSheet(intent: _FoodEntryIntent.inFridge);
                },
                icon: const Icon(Icons.kitchen_outlined, size: 18),
                label: const Text('Agregar otro a mi nevera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A6B3F),
                  side: const BorderSide(color: Color(0xFF0A6B3F)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _showAddCustomFoodSheet(intent: _FoodEntryIntent.consumed);
                },
                icon: const Icon(Icons.restaurant_outlined, size: 18),
                label: const Text('Registrar otro consumo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A6B3F),
                  side: const BorderSide(color: Color(0xFF0A6B3F)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Listo'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6B3F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi nevera',
                style: TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lo que tienes en casa. La IA lo sugiere primero cuando lo adjuntas al chat.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _showHelpDialog,
          icon: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF64748B),
          ),
          tooltip: '¿Cómo funciona?',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.kitchen_outlined, color: Color(0xFF0A6B3F), size: 24),
            SizedBox(width: 10),
            Text('Mi nevera'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpRow(
              icon: Icons.kitchen_outlined,
              title: 'Mi nevera',
              body:
                  'Alimentos que tienes guardados. Al adjuntarlos al chat, la IA los prioriza.',
            ),
            SizedBox(height: 12),
            _HelpRow(
              icon: Icons.public_rounded,
              title: 'Comunes',
              body:
                  'Catálogo general de NutriLife para cuando no encuentras lo que buscas.',
            ),
            SizedBox(height: 12),
            _HelpRow(
              icon: Icons.add_box_outlined,
              title: 'Entrada manual',
              body:
                  'Elige entre "lo tengo" (a tu nevera) o "lo consumí" (alimento registrado, sin guardar).',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFF0A6B3F),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFoodCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar personalizado',
              style: TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿No encuentras tu alimento? Agrégalo y elige si lo tienes en casa o solo lo registraste.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ManualEntryTile(
                    icon: Icons.kitchen_outlined,
                    label: 'A mi nevera',
                    onTap: () => _showAddCustomFoodSheet(
                      intent: _FoodEntryIntent.inFridge,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ManualEntryTile(
                    icon: Icons.restaurant_outlined,
                    label: 'Lo consumí',
                    onTap: () => _showAddCustomFoodSheet(
                      intent: _FoodEntryIntent.consumed,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          bottomNavigationBar:
              _selectedCommonFoodIds.isNotEmpty && !_showMine && !_isSearching
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _BulkActionBar(
                      count: _selectedCommonFoodIds.length,
                      loading:
                          _commonSelectionKey.currentState?._bulkLoading ??
                          false,
                      onClearSelection: _clearCommonSelection,
                      onFridge: () async =>
                          _commonSelectionKey.currentState?._runFridge(),
                      onConsume: () async =>
                          _commonSelectionKey.currentState?._runConsume(),
                    ),
                  ),
                )
              : null,
          body: RefreshIndicator(
            color: AppTheme.primaryStart,
            onRefresh: _viewModel.refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FoodSearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _isSearching
                              ? const SizedBox(
                                  height: 20,
                                  width: double.infinity,
                                )
                              : _buildCustomFoodCard(),
                        ),
                        const SizedBox(height: 8),
                        _buildTitle(),
                        const SizedBox(height: 14),
                        if (!_isSearching && _viewModel.foods.isNotEmpty) ...[
                          SegmentedTabs(
                            labels: const ['Mi nevera', 'Comunes'],
                            selected: _showMine ? 0 : 1,
                            onChanged: (index) {
                              _clearCommonSelection();
                              setState(() => _tab = index);
                            },
                          ),
                          const SizedBox(height: 12),
                          _ListHeader(
                            subtitle: _showMine
                                ? 'Lo que tienes guardado'
                                : 'Catálogo de NutriLife',
                            seeAllLabel: _showMine
                                ? (_viewModel.fridgeItems.length > _previewCount
                                      ? 'Ver todo'
                                      : null)
                                : (_common.length > _previewCount
                                      ? (_showAllCommon
                                            ? 'Ver menos'
                                            : 'Ver todos')
                                      : null),
                            onSeeAll: _showMine
                                ? (_viewModel.fridgeItems.length > _previewCount
                                      ? () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AllFoodsScreen(
                                                  title: 'Mi nevera',
                                                  showFridge: true,
                                                ),
                                          ),
                                        )
                                      : null)
                                : (_common.length > _previewCount
                                      ? () {
                                          _clearCommonSelection();
                                          setState(
                                            () => _showAllCommon =
                                                !_showAllCommon,
                                          );
                                        }
                                      : null),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_isSearching) ...[
                          Text(
                            'Resultados (${_viewModel.foods.length})',
                            style: const TextStyle(
                              color: Color(0xFF2C2F31),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
                ..._buildListSlivers(),
                if (!_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24.0,
                        16.0,
                        24.0,
                        16.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: Color(0xFF0284C7),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: agregar primero lo que tienes en tu nevera (no lo que comiste fuera) ayuda a la IA a sugerirte recetas con lo que ya está en casa.',
                                style: TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye la lista como slivers para que no quede espacio vacío abajo.
  /// Devuelve una lista de slivers que se insertan en el CustomScrollView.
  List<Widget> _buildListSlivers() {
    if (_viewModel.isLoading && _viewModel.foods.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryStart),
            ),
          ),
        ),
      ];
    }

    if (_viewModel.errorMessage != null &&
        _viewModel.foods.isEmpty &&
        _viewModel.fridgeItems.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _viewModel.refreshAll,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryStart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (_isSearching) {
      final foods = _viewModel.foods;
      if (foods.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Text(
                'No encontramos "${_viewModel.searchQuery.trim()}". Prueba con otro nombre o agrégalo desde "Entrada manual".',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          sliver: SliverList.separated(
            itemCount: foods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildFoodTile(foods[index], fromCommonTab: !_showMine),
          ),
        ),
      ];
    }

    // Mi nevera: ítems reales de la nevera.
    if (_showMine) {
      final items = _viewModel.fridgeItems;
      if (items.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: _EmptyMineView(),
            ),
          ),
        ];
      }
      final preview = items.take(_previewCount).toList();
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          sliver: SliverList.separated(
            itemCount: preview.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _FridgeItemTile(item: preview[index]),
          ),
        ),
      ];
    }

    // Comunes: catálogo de NutriLife con selección en lote.
    final foods = _common;
    if (foods.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Text(
              'No hay alimentos comunes cargados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ];
    }
    final visibleFoods = _showAllCommon
        ? foods
        : foods.take(_previewCount).toList();
    return [
      SliverToBoxAdapter(
        child: _BulkAddComunesSection(
          key: _commonSelectionKey,
          common: visibleFoods,
          onAddOne: _addSingleCommon,
          onSelectionChanged: (selected) {
            setState(() => _selectedCommonFoodIds = selected);
          },
          onBulkLoadingChanged: (loading) {
            if (_bulkLoading != loading) {
              setState(() => _bulkLoading = loading);
            }
          },
          onBulkFridge: _addBulkToFridge,
          onBulkConsume: _addBulkConsume,
          onBulkDone: _refreshAll,
        ),
      ),
    ];
  }

  Widget _buildFoodTile(FoodModel food, {required bool fromCommonTab}) {
    return FoodListTile(
      food: food,
      fromCommonTab: fromCommonTab,
      onAddToFridge:
          ({
            required int foodId,
            required double quantity,
            required String unit,
          }) async {
            final ok = await _viewModel.addToFridge(
              foodId: foodId,
              quantity: quantity,
              unit: unit,
            );
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? '${food.name} agregado a tu nevera'
                      : (_viewModel.errorMessage ?? 'No se pudo agregar'),
                ),
                backgroundColor: ok
                    ? const Color(0xFF0A6B3F)
                    : Colors.redAccent,
              ),
            );
            return ok;
          },
      onConsume:
          ({
            required int foodId,
            required double quantity,
            required MealType mealType,
          }) async {
            final ok = await _viewModel.consumeFood(
              foodId: foodId,
              quantity: quantity,
              mealType: mealType,
            );
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? '${food.name} registrado en ${_mealLabel(mealType)}'
                      : (_viewModel.errorMessage ?? 'No se pudo registrar'),
                ),
                backgroundColor: ok
                    ? const Color(0xFF0A6B3F)
                    : Colors.redAccent,
              ),
            );
            return ok;
          },
    );
  }

  Future<void> _addSingleCommon(FoodModel food) async {
    final result = await CommonFoodActionsSheet.show(
      context,
      food: food,
      emoji: _emojiFor(food.name),
    );
    if (!mounted || result == null) return;
    if (result.action == CommonFoodAction.fridge) {
      final ok = await _viewModel.addToFridge(
        foodId: food.foodId,
        quantity: result.quantity,
        unit: result.unit,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${food.name} agregado a tu nevera'
                : (_viewModel.errorMessage ?? 'No se pudo agregar'),
          ),
          backgroundColor: ok ? const Color(0xFF0A6B3F) : Colors.redAccent,
        ),
      );
    } else {
      final ok = await _viewModel.consumeFood(
        foodId: food.foodId,
        quantity: result.quantity,
        mealType: result.mealType!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${food.name} registrado en ${_mealLabel(result.mealType!)}'
                : (_viewModel.errorMessage ?? 'No se pudo registrar'),
          ),
          backgroundColor: ok ? const Color(0xFF0A6B3F) : Colors.redAccent,
        ),
      );
    }
  }

  Future<({int ok, List<String> failed, int total, MealType mealType})>
  _addBulkToFridge(
    List<FoodModel> foods, {
    double quantity = 1,
    String unit = '1 UNIDAD',
  }) async {
    final entries = foods
        .map((f) => (food: f, quantity: quantity, unit: unit))
        .toList();
    final res = await _viewModel.addBatchToFridge(entries);
    return (
      ok: res.ok,
      failed: res.failed,
      total: foods.length,
      mealType: MealType.breakfast,
    );
  }

  Future<({int ok, List<String> failed, int total, MealType mealType})>
  _addBulkConsume(
    List<FoodModel> foods,
    MealType mealType, {
    double quantity = 1,
  }) async {
    final entries = foods.map((f) => (food: f, quantity: quantity)).toList();
    final res = await _viewModel.consumeBatch(entries, mealType);
    return (
      ok: res.ok,
      failed: res.failed,
      total: foods.length,
      mealType: mealType,
    );
  }

  void _clearCommonSelection() {
    final selectionState = _commonSelectionKey.currentState;
    if (selectionState != null) {
      selectionState._clearSelection();
    } else if (_selectedCommonFoodIds.isNotEmpty) {
      setState(() => _selectedCommonFoodIds = {});
    }
  }

  Future<void> _refreshAll() async {
    await _viewModel.fetchFoods();
  }

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

  String _mealLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'desayuno';
      case MealType.lunch:
        return 'almuerzo';
      case MealType.dinner:
        return 'cena';
      case MealType.snack:
        return 'snack';
    }
  }
}

class _ListHeader extends StatelessWidget {
  final String subtitle;

  /// Texto que aparece si hay más ítems de los que se muestran en preview.
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  const _ListHeader({required this.subtitle, this.seeAllLabel, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          if (onSeeAll != null && seeAllLabel != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllLabel!,
                    style: const TextStyle(
                      color: Color(0xFF0A6B3F),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFF0A6B3F),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Intención de la entrada manual: guardar en nevera o solo registrar.
enum _FoodEntryIntent { inFridge, consumed }

class _ManualEntryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ManualEntryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0A6B3F), size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HelpRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF6EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0A6B3F), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lista seleccionable de alimentos comunes con acciones en lote
/// (a mi nevera o lo consumí).
class _BulkAddComunesSection extends StatefulWidget {
  final List<FoodModel> common;
  final Future<void> Function(FoodModel) onAddOne;
  final ValueChanged<Set<int>> onSelectionChanged;
  final ValueChanged<bool> onBulkLoadingChanged;
  final Future<({int ok, List<String> failed, int total, MealType mealType})>
  Function(List<FoodModel>, {double quantity, String unit})
  onBulkFridge;
  final Future<({int ok, List<String> failed, int total, MealType mealType})>
  Function(List<FoodModel>, MealType, {double quantity})
  onBulkConsume;
  final Future<void> Function() onBulkDone;

  const _BulkAddComunesSection({
    super.key,
    required this.common,
    required this.onAddOne,
    required this.onSelectionChanged,
    required this.onBulkLoadingChanged,
    required this.onBulkFridge,
    required this.onBulkConsume,
    required this.onBulkDone,
  });

  @override
  State<_BulkAddComunesSection> createState() => _BulkAddComunesSectionState();
}

class _BulkAddComunesSectionState extends State<_BulkAddComunesSection> {
  final Set<int> _selected = {};
  bool _bulkLoading = false;

  void _toggle(int foodId) {
    setState(() {
      if (_selected.contains(foodId)) {
        _selected.remove(foodId);
      } else {
        _selected.add(foodId);
      }
    });
    widget.onSelectionChanged(_selected.toSet());
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(_selected.clear);
    widget.onSelectionChanged({});
  }

  Future<void> _runFridge() => _runBulk(() async {
    final selected = widget.common
        .where((food) => _selected.contains(food.foodId))
        .toList();
    return widget.onBulkFridge(selected, quantity: 1, unit: '1 UNIDAD');
  });

  Future<void> _runConsume() async {
    final mealType = await _askMealType();
    if (!mounted || mealType == null) return;
    await _runBulk(() async {
      final selected = widget.common
          .where((food) => _selected.contains(food.foodId))
          .toList();
      return widget.onBulkConsume(selected, mealType, quantity: 1);
    });
  }

  Future<void> _runBulk(
    Future<({int ok, List<String> failed, int total, MealType mealType})>
    Function()
    op,
  ) async {
    if (_selected.isEmpty || _bulkLoading) return;
    setState(() => _bulkLoading = true);
    widget.onBulkLoadingChanged(true);
    final res = await op();
    if (!mounted) return;
    setState(() {
      _bulkLoading = false;
      _selected.clear();
    });
    widget.onBulkLoadingChanged(false);
    widget.onSelectionChanged({});
    await widget.onBulkDone();
    if (!mounted) return;
    final failed = res.failed.isEmpty
        ? ''
        : ' Fallaron: ${res.failed.join(", ")}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${res.ok}/${res.total} procesados correctamente.$failed',
        ),
        backgroundColor: res.failed.isEmpty
            ? const Color(0xFF0A6B3F)
            : (res.ok == 0 ? Colors.redAccent : const Color(0xFFD97706)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final food in widget.common)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectableFoodTile(
                food: food,
                selected: _selected.contains(food.foodId),
                onTap: () => _toggle(food.foodId),
                onAddOne: () => widget.onAddOne(food),
              ),
            ),
        ],
      ),
    );
  }

  Future<MealType?> _askMealType() async {
    return showModalBottomSheet<MealType>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const SizedBox(height: 12),
                const Text(
                  '¿En qué comida?',
                  style: TextStyle(
                    color: Color(0xFF2C2F31),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se registrará como consumido en la comida seleccionada para todos los alimentos marcados.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                for (final t in MealType.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      t.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      t.label(sheetContext.l10n),
                      style: const TextStyle(
                        color: Color(0xFF2C2F31),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(t),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableFoodTile extends StatelessWidget {
  final FoodModel food;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onAddOne;

  const _SelectableFoodTile({
    required this.food,
    required this.selected,
    required this.onTap,
    required this.onAddOne,
  });

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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? const Color(0xFF0A6B3F) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF0A6B3F) : Colors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF0A6B3F)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _emojiFor(food.name),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        color: Color(0xFF2C2F31),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${food.caloriesPerUnit.toInt()} kcal · ${food.baseUnit}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAddOne,
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF0A6B3F)),
                tooltip: 'Acciones',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final bool loading;
  final VoidCallback onClearSelection;
  final Future<void> Function() onFridge;
  final Future<void> Function() onConsume;

  const _BulkActionBar({
    required this.count,
    required this.loading,
    required this.onClearSelection,
    required this.onFridge,
    required this.onConsume,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: onClearSelection,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                  tooltip: 'Quitar selección',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'alimento seleccionado' : 'alimentos seleccionados'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2C2F31),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onFridge,
                    icon: const Icon(Icons.kitchen_outlined, size: 16),
                    label: const Text('A mi nevera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onConsume,
                    icon: const Icon(Icons.restaurant_outlined, size: 16),
                    label: const Text('Lo consumí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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

/// Estado vacío cuando la nevera no tiene ítems. Se muestra como bloque
/// compacto para que el scroll no deje espacio raro debajo.
class _EmptyMineView extends StatelessWidget {
  const _EmptyMineView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(28),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen_outlined, color: Color(0xFF94A3B8), size: 44),
            SizedBox(height: 12),
            Text(
              'Tu nevera está vacía',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Agrega lo que tienes en casa desde "Entrada manual" para que la IA pueda sugerírtelo en el chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de un ítem real de la nevera del usuario (fridge_items).
/// Muestra nombre, cantidad y unidad.
class _FridgeItemTile extends StatelessWidget {
  final FridgeItemModel item;

  const _FridgeItemTile({required this.item});

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
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
        ],
      ),
    );
  }
}
