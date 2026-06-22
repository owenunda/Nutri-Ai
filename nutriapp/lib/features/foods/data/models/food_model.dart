class FoodModel {
  final int foodId;
  final String name;
  final double caloriesPerUnit;
  final String baseUnit;
  final bool isGlobal;
  final bool isActive;
  final int? createdByUserId;

  FoodModel({
    required this.foodId,
    required this.name,
    required this.caloriesPerUnit,
    required this.baseUnit,
    required this.isGlobal,
    required this.isActive,
    this.createdByUserId,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodId: json['foodId'] ?? 0,
      name: json['name'] ?? '',
      caloriesPerUnit: (json['caloriesPerUnit'] is num)
          ? (json['caloriesPerUnit'] as num).toDouble()
          : double.tryParse(json['caloriesPerUnit']?.toString() ?? '') ?? 0.0,
      baseUnit: json['baseUnit'] ?? '',
      isGlobal: json['isGlobal'] ?? false,
      isActive: json['isActive'] ?? true,
      createdByUserId: json['createdByUserId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'caloriesPerUnit': caloriesPerUnit,
      'baseUnit': baseUnit,
      'isGlobal': isGlobal,
      'isActive': isActive,
      'createdByUserId': createdByUserId,
    };
  }
}
