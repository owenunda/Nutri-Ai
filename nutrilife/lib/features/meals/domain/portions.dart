const double kMinPortions = 0.5;
const double kMaxPortions = 10.0;
const double kPortionStep = 0.5;

final _numericUnit = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(g|ml)\s*$', caseSensitive: false);

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
    return '$shown ${match.group(2)!.toLowerCase()}';
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
