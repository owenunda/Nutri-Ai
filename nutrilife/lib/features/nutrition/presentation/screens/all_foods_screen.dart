import 'package:flutter/material.dart';
import '../../data/models/food_model.dart';
import '../controllers/foods_view_model.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_field.dart';

/// Lista completa de alimentos, con su propio buscador. Recibe los alimentos
/// ya cargados en la pantalla anterior para abrir al instante.
class AllFoodsScreen extends StatefulWidget {
  final List<FoodModel> foods;

  const AllFoodsScreen({super.key, required this.foods});

  @override
  State<AllFoodsScreen> createState() => _AllFoodsScreenState();
}

class _AllFoodsScreenState extends State<AllFoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<FoodModel> _visible = widget.foods;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _visible =
            FoodsViewModel.filterFoods(widget.foods, _searchController.text);
      });
    });
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
        title: const Text(
          'Todos los alimentos',
          style: TextStyle(
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
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: count,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => FoodListTile(food: _visible[index]),
            ),
          ),
        ],
      ),
    );
  }
}
