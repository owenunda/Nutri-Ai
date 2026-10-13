const double kMinPortions = 0.5;
const double kMaxPortions = 10.0;
const double kPortionStep = 0.5;

// "100 G", "100 ml" o con detalle: "100 G COCIDO".
final _numericUnit = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(g|ml)\b\s*(.*)$', caseSensitive: false);
final _leadingAmount = RegExp(r'^\s*(\d+(?:[.,]\d+)?)');

/// Cuánto mide la unidad base: "100 G" → 100, "2 grandes" → 2,
/// "1 UNIDAD" → 1. Sin número al inicio, 1.
double baseAmountOf(String baseUnit) {
  final match = _leadingAmount.firstMatch(baseUnit);
  final value = match == null ? 1.0 : double.parse(match.group(1)!.replaceAll(',', '.'));
  return value > 0 ? value : 1;
}

/// El chef da cantidades naturales (300 g, 1 pera); el backend guarda
/// cuántas unidades base son: 300 g de "100 G" → 3, 1 pera de "2 grandes" → 0,5.
double toBaseUnits(num naturalQuantity, String baseUnit) => naturalQuantity / baseAmountOf(baseUnit);

/// 0.5 → "½", 1 → "1", 1.5 → "1½".
String portionsLabel(double portions) {
  final whole = portions.floor();
  final hasHalf = (portions - whole) >= 0.5;
  if (whole == 0) return hasHalf ? '½' : '0';
  return hasHalf ? '$whole½' : '$whole';
}

/// "150 g" si la unidad base es numérica (100 G), si no "1½ unidad".
String quantityLabel(double portions, String baseUnit) {
  final match = _numericUnit.firstMatch(baseUnit);
  if (match != null) {
    final amount = double.parse(match.group(1)!.replaceAll(',', '.')) * portions;
    final shown = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
    final detail = match.group(3)!.trim().toLowerCase();
    return '$shown ${match.group(2)!.toLowerCase()}${detail.isEmpty ? '' : ' $detail'}';
  }
  final unit = baseUnit.trim().replaceFirst(RegExp(r'^\d+\s*'), '').toLowerCase();
  return '${portionsLabel(portions)} $unit';
}

int caloriesFor(double portions, double caloriesPerUnit) =>
    (portions * caloriesPerUnit).round();

/// Cantidad de un ingrediente de receta: "17 g", o "0,25 unidad" si la unidad
/// no es numérica (las fracciones de receta no siempre son medias).
String ingredientAmountLabel(double quantity, String baseUnit) {
  if (_numericUnit.hasMatch(baseUnit)) return quantityLabel(quantity, baseUnit);
  final unit = baseUnit.trim().replaceFirst(RegExp(r'^\d+\s*'), '').toLowerCase();
  final shown = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '').replaceAll('.', ',');
  return '$shown $unit';
}
