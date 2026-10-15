/// Unidades base que se pueden elegir al crear un alimento propio. El valor
/// es el que se guarda (mismo formato que el catálogo: "100 G", "1 UNIDAD");
/// la etiqueta es lo que ve el usuario.
const List<({String value, String label})> kFoodUnits = [
  (value: '100 G', label: '100 g'),
  (value: '100 ML', label: '100 ml'),
  (value: '1 UNIDAD', label: '1 unidad'),
  (value: '1 PORCIÓN', label: '1 porción'),
  (value: '1 TAZA', label: '1 taza'),
  (value: '1 CUCHARADA', label: '1 cucharada'),
  (value: '1 REBANADA', label: '1 rebanada'),
];

/// La mayoría del catálogo (y las etiquetas nutricionales) van por 100 g.
const String kDefaultFoodUnit = '100 G';

/// Mapea el valor guardado ("1 UNIDAD", "100 G", etc.) a una etiqueta
/// corta y legible para mostrar al usuario.
String prettyUnitLabel(String value) {
  for (final option in kFoodUnits) {
    if (option.value == value) return option.label;
  }
  final normalized = value.trim().toLowerCase();
  if (const {'g', 'kg', 'ml', 'l'}.contains(normalized)) return normalized;
  // Si el valor no está en la lista (ej. unidades viejas de la BD), al
  // menos capitalizamos la primera letra para que se vea mejor.
  if (normalized.isEmpty) return normalized;
  return normalized[0].toUpperCase() + normalized.substring(1);
}

/// Formatea [quantity] + [unit] para mostrarlos juntos sin redundancias.
/// Si la unidad ya empieza con la cantidad (ej. "1 UNIDAD" con quantity 1),
/// se omite la cantidad para no duplicar.
String formatQuantityWithUnit(double quantity, String unit) {
  final prettyUnit = prettyUnitLabel(unit);
  final normalizedUnit = unit.trim().toUpperCase();
  const countedUnits = {
    '1 UNIDAD': 'unidad',
    '1 PORCIÓN': 'porción',
    '1 TAZA': 'taza',
    '1 CUCHARADA': 'cucharada',
    '1 REBANADA': 'rebanada',
  };
  final countedUnit = countedUnits[normalizedUnit];
  if (countedUnit != null) {
    final formattedQuantity = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
    if (quantity == 1) return '1 $countedUnit';
    final plural = countedUnit == 'unidad' ? 'unidades' : '${countedUnit}s';
    return '$formattedQuantity $plural';
  }
  final q = quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toString();
  return '$q $prettyUnit';
}
