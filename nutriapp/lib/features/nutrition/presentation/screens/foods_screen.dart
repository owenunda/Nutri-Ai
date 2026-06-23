import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/food_model.dart';
import '../controllers/foods_view_model.dart';

class FoodsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const FoodsScreen({super.key, this.user});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  late final FoodsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = FoodsViewModel();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppTheme.primaryStart,
          onRefresh: _viewModel.fetchFoods,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            color: Color(0xFF2C2F31),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search 100,000+ foods...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6DE8A2), Color(0xFF53D48B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Identify with AI',
                              style: TextStyle(
                                color: Color(0xFF0F3D26),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Take a photo of your meal to instantly log nutrition data.',
                              style: TextStyle(
                                color: Color(0xFF0F3D26),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A6B3F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El escaneo de comida con cámara estará disponible próximamente.'),
                                    backgroundColor: AppTheme.primaryStart,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text(
                                'SCAN MEAL',
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
                      const SizedBox(height: 16),
                      Container(
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
                              'Add Custom',
                              style: TextStyle(
                                color: Color(0xFF2C2F31),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Can't find your food? Add your own nutritional details manually.",
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
                                'MANUAL ENTRY',
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
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Common Foods',
                                style: TextStyle(
                                  color: Color(0xFF2C2F31),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Based on your recent activity',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'See all',
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
                _buildFoodsContent(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0),
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
                            'Pro Tip: Logging your protein first helps you hit your satiety goals 20% faster today.',
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
                'Tu base de datos está vacía. ¡Presiona "Manual Entry" arriba para registrar tu primer alimento!',
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _viewModel.foods.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final food = _viewModel.foods[index];
        return _buildFoodItemCard(food);
      },
    );
  }

  Widget _buildFoodItemCard(FoodModel food) {
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
                  food.baseUnit.toUpperCase(),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡${food.name} registrada! Se agregaron ${food.caloriesPerUnit.toInt()} KCAL a tu registro diario.'),
                  backgroundColor: AppTheme.primaryStart,
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF0A6B3F), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
