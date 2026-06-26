import 'package:flutter/material.dart';
import '../../data/food_repository.dart';
import '../../data/models/food_model.dart';

class FoodsViewModel extends ChangeNotifier {
  final FoodRepository _foodRepository;

  FoodsViewModel({FoodRepository? foodRepository})
      : _foodRepository = foodRepository ?? FoodRepository();

  List<FoodModel> _allFoods = [];
  List<FoodModel> _filteredFoods = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<FoodModel> get foods => _filteredFoods;
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

  void searchFoods(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredFoods = List.from(_allFoods);
    } else {
      final lowercaseQuery = _searchQuery.toLowerCase();
      _filteredFoods = _allFoods.where((food) {
        return food.name.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
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
      _allFoods.add(newFood);
      _applyFilter();
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
}
