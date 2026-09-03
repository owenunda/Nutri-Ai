/// Un producto guardado en la nevera del usuario.
class FridgeItemModel {
  final int fridgeItemId;
  final int foodId;
  final String name;
  final double quantity;
  final String unit;
  final double caloriesPerUnit;
  final String baseUnit;

  const FridgeItemModel({
    required this.fridgeItemId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.foodId = 0,
    this.caloriesPerUnit = 0,
    this.baseUnit = '',
  });

  /// Hay calorías que mostrar solo si el backend las mandó.
  bool get hasCalories => caloriesPerUnit > 0;

  factory FridgeItemModel.fromJson(Map<String, dynamic> json) {
    return FridgeItemModel(
      fridgeItemId: json['fridgeItemId'] ?? 0,
      foodId: json['foodId'] ?? 0,
      name: json['name'] ?? '',
      quantity: _toDouble(json['quantity']),
      unit: json['unit'] ?? '',
      caloriesPerUnit: _toDouble(json['caloriesPerUnit']),
      baseUnit: json['baseUnit'] ?? '',
    );
  }
}

/// Postgres puede serializar numeric como texto, así que no basta con castear.
double _toDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0.0;
