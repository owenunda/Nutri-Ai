import 'package:flutter/material.dart';
import '../../../meals/domain/meal_type.dart';
import '../../data/food_repository.dart';
import '../../data/models/food_model.dart';
import '../controllers/foods_view_model.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_field.dart';

/// Lista completa de alimentos, con su propio buscador. Si recibe los alimentos
/// ya cargados abre al instante; si no, los carga. Con [mealType] sirve para
/// elegir qué agregar a esa comida.
class AllFoodsScreen extends StatefulWidget {
  final List<FoodModel>? foods;
  final MealType? mealType;
  final FoodRepository? foodRepository;

  const AllFoodsScreen({super.key, this.foods, this.mealType, this.foodRepository});

  @override
  State<AllFoodsScreen> createState() => _AllFoodsScreenState();
}

class _AllFoodsScreenState extends State<AllFoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodModel> _all = const [];
  List<FoodModel> _visible = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _visible = FoodsViewModel.filterFoods(_all, _searchController.text);
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
      final foods = await (widget.foodRepository ?? FoodRepository()).getFoods();
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
    final count = _visible.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
        title: Text(
          widget.mealType == null
              ? 'Todos los alimentos'
              : 'Agregar a ${widget.mealType!.label}',
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
              '$count ${count == 1 ? 'alimento' : 'alimentos'}',
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
                            TextButton(onPressed: _load, child: const Text('Reintentar')),
                          ],
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: count,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => FoodListTile(
                          food: _visible[index],
                          mealType: widget.mealType,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
