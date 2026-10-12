import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/food_repository.dart';
import '../controllers/foods_view_model.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_field.dart';
import 'all_foods_screen.dart';

class FoodsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  @visibleForTesting
  final FoodRepository? foodRepository;

  const FoodsScreen({super.key, this.user, this.foodRepository});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  late final FoodsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// En la vista normal solo se ven unos pocos; el resto está en "Ver todo".
  static const _previewCount = 5;

  /// Buscando, la tarjeta y el consejo se esconden para que el teclado no
  /// tape los resultados.
  bool get _isSearching =>
      _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _viewModel = FoodsViewModel(foodRepository: widget.foodRepository);
    _searchFocusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchFoods();
    });
    _searchController.addListener(() {
      _viewModel.searchFoods(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showAddCustomFoodSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final unitController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  const SizedBox(height: 24),
                  const Text(
                    'Nuevo Alimento',
                    style: TextStyle(
                      color: Color(0xFF2C2F31),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registra tus propios detalles nutricionales personalizados en la base de datos.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: caloriesController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Calorías (Kcal)',
                            hintText: 'Ej. 105',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Porción/Unidad base',
                            hintText: 'Ej. 1 mediana',
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
                              return 'Ingresa unidad base';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      return PrimaryButton(
                        textButton: _viewModel.isLoading ? 'Guardando...' : 'Guardar Alimento',
                        width: double.infinity,
                        icon: Icons.check,
                        onPressed: _viewModel.isLoading
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  final success = await _viewModel.addCustomFood(
                                    name: nameController.text.trim(),
                                    calories: double.parse(caloriesController.text),
                                    baseUnit: unitController.text.trim(),
                                  );

                                  if (success) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('¡Alimento personalizado registrado exitosamente!'),
                                          backgroundColor: AppTheme.primaryStart,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_viewModel.errorMessage ?? 'Error al guardar alimento'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
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
        );
      },
    );
  }

  Widget _buildCustomFoodCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar personalizado',
              style: TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¿No encuentras tu alimento? Agrega tus propios detalles nutricionales manualmente.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2C2F31),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: _showAddCustomFoodSheet,
              icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF0A6B3F)),
              label: const Text(
                'ENTRADA MANUAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAllFoods() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllFoodsScreen(foods: _viewModel.foods),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppTheme.primaryStart,
          onRefresh: _viewModel.fetchFoods,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    FoodSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: _isSearching
                          ? const SizedBox(height: 20, width: double.infinity)
                          : _buildCustomFoodCard(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSearching
                                    ? 'Resultados (${_viewModel.foods.length})'
                                    : 'Alimentos comunes',
                                style: const TextStyle(
                                  color: Color(0xFF2C2F31),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (!_isSearching) ...[
                                const SizedBox(height: 2),
                                const Text(
                                  'Basado en tu actividad reciente',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_isSearching)
                        TextButton(
                          onPressed: _openAllFoods,
                          child: const Text(
                            'Ver todo',
                            style: TextStyle(
                              color: Color(0xFF0A6B3F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: _buildFoodsContent(),
              ),
              if (!_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
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
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF0284C7),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consejo: Registrar tu proteína primero te ayuda a alcanzar tus objetivos de saciedad un 20% más rápido.',
                          style: TextStyle(
                            color: Color(0xFF0369A1),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodsContent() {
    if (_viewModel.isLoading && _viewModel.foods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryStart),
        ),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.foods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 8),
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _viewModel.fetchFoods,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryStart),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.foods.isEmpty && _viewModel.searchQuery.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Text(
          'No encontramos "${_viewModel.searchQuery.trim()}". Prueba con otro nombre o agrégalo con Entrada manual.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    if (_viewModel.foods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(32),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded, color: Color(0xFF94A3B8), size: 48),
              SizedBox(height: 16),
              Text(
                'No hay alimentos cargados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tu base de datos está vacía. ¡Presiona "Entrada Manual" arriba para registrar tu primer alimento!',
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

    final foods = _isSearching
        ? _viewModel.foods
        : _viewModel.foods.take(_previewCount).toList();

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      itemCount: foods.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => FoodListTile(food: foods[index]),
    );
  }
}
