/// Un producto guardado en la nevera del usuario.
///
/// `GET /fridge` devuelve los items sin `foodId` (ver fridge.repository.js),
/// así que aquí solo viaja lo que sirve para mostrarlos y nombrarlos.
class FridgeItemModel {
  final int fridgeItemId;
  final String name;
  final double quantity;
  final String unit;

  const FridgeItemModel({
    required this.fridgeItemId,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory FridgeItemModel.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'];
    return FridgeItemModel(
      fridgeItemId: json['fridgeItemId'] ?? 0,
      name: json['name'] ?? '',
      // Postgres puede serializar numeric como texto, así que no basta con castear.
      quantity: rawQuantity is num
          ? rawQuantity.toDouble()
          : double.tryParse(rawQuantity?.toString() ?? '') ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }
}
