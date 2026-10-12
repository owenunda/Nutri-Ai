import '../../domain/meal_type.dart';

class MealItem {
  final int detailId;
  final int foodId;
  final String name;
  final String baseUnit;
  final double quantity;
  final int calories;

  const MealItem({
    required this.detailId,
    required this.foodId,
    required this.name,
    required this.baseUnit,
    required this.quantity,
    required this.calories,
  });

  factory MealItem.fromJson(Map map) => MealItem(
        detailId: (map['detailId'] as num).toInt(),
        foodId: (map['foodId'] as num).toInt(),
        name: map['name'] as String? ?? '',
        baseUnit: map['baseUnit'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        calories: (map['calories'] as num?)?.round() ?? 0,
      );
}

class MealGroup {
  final MealType type;
  final int totalCalories;
  final List<MealItem> items;

  const MealGroup({required this.type, required this.totalCalories, required this.items});

  bool get isEmpty => items.isEmpty;

  /// "Tilapia, Arroz • 240 kcal" o "Aún no registrada".
  String get summary => isEmpty
      ? 'Aún no registrada'
      : '${items.map((i) => i.name).join(', ')} • $totalCalories kcal';

  factory MealGroup.fromJson(MealType type, Map? map) => MealGroup(
        type: type,
        totalCalories: (map?['totalCalories'] as num?)?.round() ?? 0,
        items: (map?['items'] as List? ?? const [])
            .whereType<Map>()
            .map(MealItem.fromJson)
            .toList(),
      );
}

class DayMeals {
  final String date;
  final int totalCalories;
  final Map<MealType, MealGroup> _groups;

  DayMeals({required this.date, required this.totalCalories, required Map<MealType, MealGroup> groups})
      : _groups = groups;

  MealGroup of(MealType type) =>
      _groups[type] ?? MealGroup(type: type, totalCalories: 0, items: const []);

  factory DayMeals.fromJson(Map map) {
    final meals = map['meals'] as Map? ?? const {};
    return DayMeals(
      date: map['date'] as String? ?? '',
      totalCalories: (map['totalCalories'] as num?)?.round() ?? 0,
      groups: {
        for (final type in MealType.values)
          type: MealGroup.fromJson(type, meals[type.apiValue] as Map?),
      },
    );
  }

  factory DayMeals.empty(String date) =>
      DayMeals(date: date, totalCalories: 0, groups: const {});
}
