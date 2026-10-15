import 'package:flutter/material.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/domain/meal_type.dart';
import '../../data/food_repository.dart';
import '../../data/fridge_repository.dart';
import '../../data/models/food_model.dart';
import '../../data/models/fridge_item_model.dart';

class FoodsViewModel extends ChangeNotifier {
  final FoodRepository _foodRepository;
  final FridgeRepository _fridgeRepository;
  final MealRepository _mealRepository;

  FoodsViewModel({
    FoodRepository? foodRepository,
    FridgeRepository? fridgeRepository,
    MealRepository? mealRepository,
  })  : _foodRepository = foodRepository ?? FoodRepository(),
        _fridgeRepository = fridgeRepository ?? FridgeRepository(),
        _mealRepository = mealRepository ?? MealRepository();

  List<FoodModel> _allFoods = [];
  List<FoodModel> _filteredFoods = [];
  List<FridgeItemModel> _fridgeItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<FoodModel> get foods => _filteredFoods;
  List<FridgeItemModel> get fridgeItems => _fridgeItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> fetchFoods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedFoods = await _foodRepository.getFoods();
      _allFoods = fetchedFoods;
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga la lista de la nevera real del backend. Es lo que muestra
  /// la pestaña "Mi nevera" para reflejar lo que tiene el usuario guardado.
  Future<void> fetchFridge() async {
    try {
      _fridgeItems = await _fridgeRepository.getFridgeItems();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Recarga alimentos y nevera de una sola vez. Útil en pull-to-refresh
  /// y tras agregar ítems.
  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    final foodsFuture = _foodRepository.getFoods().then((v) {
      _allFoods = v;
      _applyFilter();
    }).catchError((_) {
      // Si falla, mantenemos la lista anterior; el snackbar se ve en
      // `_fetchAllWithErrors` si lo prefieres mostrar.
    });
    final fridgeFuture = _fridgeRepository.getFridgeItems().then((v) {
      _fridgeItems = v;
    }).catchError((_) {});
    await Future.wait([foodsFuture, fridgeFuture]);
    _isLoading = false;
    notifyListeners();
  }

  void searchFoods(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredFoods = filterFoods(_allFoods, _searchQuery);
  }

  /// Alimentos cuyo nombre contiene [query]. Lo usa también la lista completa.
  static List<FoodModel> filterFoods(List<FoodModel> foods, String query) {
    if (query.trim().isEmpty) return List.from(foods);
    final lowercaseQuery = query.toLowerCase();
    return foods.where((food) {
      return food.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<bool> addCustomFood({
    required String name,
    required double calories,
    required String baseUnit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newFood = await _foodRepository.createFood(
        name: name,
        caloriesPerUnit: calories,
        baseUnit: baseUnit,
      );
      // Refresca desde el backend para tener el id canónico. Sin esto, si el
      // usuario ya tenía un alimento con el mismo nombre, el `firstWhere`
      // local devolvería el viejo y el POST /fridge/items o /meals/items
      // apuntaría a un foodId incorrecto.
      try {
        final fresh = await _foodRepository.getFoods();
        _allFoods = fresh;
        _applyFilter();
      } catch (_) {
        _allFoods.add(newFood);
        _applyFilter();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Busca un alimento por nombre en la lista local. Si no está, devuelve 0.
  int findFoodIdByName(String name) {
    for (final f in _allFoods) {
      if (f.name == name) return f.foodId;
    }
    return 0;
  }

  /// Registra [foodId] en la nevera con [quantity] [unit] y refresca la
  /// lista de la nevera para que la pestaña "Mi nevera" la refleje.
  Future<bool> addToFridge({
    required int foodId,
    required double quantity,
    required String unit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fridgeRepository.addItem(
        foodId: foodId,
        quantity: quantity,
        unit: unit,
      );
      // Refresca la nevera para mostrar el ítem recién agregado.
      try {
        _fridgeItems = await _fridgeRepository.getFridgeItems();
      } catch (_) {/* ignore: la próxima pantalla refrescará */}
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Variante batch para meter varios alimentos comunes a la nevera de una
  /// sola vez. Devuelve la cantidad de éxitos y los nombres que fallaron.
  Future<({int ok, List<String> failed})> addBatchToFridge(
    List<({FoodModel food, double quantity, String unit})> entries,
  ) async {
    final results = await _fridgeRepository.addItems(
      entries
          .map((e) => (
                foodId: e.food.foodId,
                quantity: e.quantity,
                unit: e.unit,
              ))
          .toList(),
    );
    final ok = results.values.where((m) => m.isEmpty).length;
    final failedIds = results.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
    final failedNames = entries
        .where((e) => failedIds.contains(e.food.foodId))
        .map((e) => e.food.name)
        .toList();
    try {
      _fridgeItems = await _fridgeRepository.getFridgeItems();
    } catch (_) {}
    notifyListeners();
    return (ok: ok, failed: failedNames);
  }

  /// Registra el consumo del alimento en la comida del día indicada.
  Future<bool> consumeFood({
    required int foodId,
    required double quantity,
    required MealType mealType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _mealRepository.addFood(
        foodId: foodId,
        portions: quantity,
        type: mealType,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Variante batch para consumir varios alimentos a la vez (mismo mealType).
  Future<({int ok, List<String> failed})> consumeBatch(
    List<({FoodModel food, double quantity})> entries,
    MealType mealType,
  ) async {
    int ok = 0;
    final failed = <String>[];
    for (final e in entries) {
      try {
        await _mealRepository.addFood(
          foodId: e.food.foodId,
          portions: e.quantity,
          type: mealType,
        );
        ok += 1;
      } catch (_) {
        failed.add(e.food.name);
      }
    }
    return (ok: ok, failed: failed);
  }
}
