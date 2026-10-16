import '../../../core/l10n/l10n.dart';

/// Códigos de las unidades base que se pueden elegir al crear un alimento
/// propio. Es lo que se guarda (mismo formato que el catálogo: "100 G",
/// "1 UNIDAD") y nunca se traduce; lo que ve el usuario sale de
/// [prettyUnitLabel].
const List<String> kFoodUnitValues = [
  '100 G',
  '100 ML',
  '1 UNIDAD',
  '1 PORCIÓN',
  '1 TAZA',
  '1 CUCHARADA',
  '1 REBANADA',
];

/// Opciones para el selector de unidad: [value] es el código que se guarda y
/// [label] el nombre traducido que se muestra.
List<({String value, String label})> foodUnitOptions(AppLocalizations l10n) => [
  for (final value in kFoodUnitValues)
    (value: value, label: prettyUnitLabel(value, l10n)),
];

/// La mayoría del catálogo (y las etiquetas nutricionales) van por 100 g.
const String kDefaultFoodUnit = '100 G';

/// Mapea el valor guardado ("1 UNIDAD", "100 G", etc.) a una etiqueta
/// corta y legible para mostrar al usuario, en el idioma de la app.
String prettyUnitLabel(String value, AppLocalizations l10n) {
  switch (value.trim().toUpperCase()) {
    case '100 G':
      return '100 g';
    case '100 ML':
      return '100 ml';
    case '1 UNIDAD':
      return l10n.nutritionUnitOne;
    case '1 PORCIÓN':
      return l10n.nutritionUnitServing;
    case '1 TAZA':
      return l10n.nutritionUnitCup;
    case '1 CUCHARADA':
      return l10n.nutritionUnitTablespoon;
    case '1 REBANADA':
      return l10n.nutritionUnitSlice;
  }
  final normalized = value.trim().toLowerCase();
  if (const {'g', 'kg', 'ml', 'l'}.contains(normalized)) return normalized;
  if (normalized.isEmpty) return normalized;
  final known = _knownUnit(normalized);
  if (known != null) {
    final amount = _leadingNumber.firstMatch(normalized)?.group(0)?.trim();
    // Con cantidad ("200 G", "2 UNIDADES") se conserva y solo se traduce la
    // unidad, concordando con la cantidad.
    if (amount != null) {
      final count = num.tryParse(amount.replaceAll(',', '.'));
      return '$amount ${_unitWord(known, l10n, count)}';
    }
    // Palabra suelta de una unidad conocida (ej. "unidad" de la BD vieja): se
    // muestra traducida. g y ml quedan en minúsculas.
    final word = _unitWord(known, l10n, null);
    if (known == _KnownUnit.gram || known == _KnownUnit.milliliter) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
  // Si el valor no está en la lista, al menos capitalizamos la primera letra
  // para que se vea mejor.
  return normalized[0].toUpperCase() + normalized.substring(1);
}

enum _KnownUnit { unit, serving, cup, tablespoon, slice, gram, milliliter }

final _leadingNumber = RegExp(r'^\d+(?:[.,]\d+)?\s*');

/// La unidad sin la cantidad del inicio ("1 UNIDAD" → "unidad"), en minúsculas.
String _bareUnit(String rawUnit) =>
    rawUnit.trim().replaceFirst(_leadingNumber, '').toLowerCase();

_KnownUnit? _knownUnit(String rawUnit) {
  switch (_bareUnit(rawUnit)) {
    case 'unidad':
    case 'unidades':
      return _KnownUnit.unit;
    case 'porción':
    case 'porcion':
    case 'porciones':
      return _KnownUnit.serving;
    case 'taza':
    case 'tazas':
      return _KnownUnit.cup;
    case 'cucharada':
    case 'cucharadas':
      return _KnownUnit.tablespoon;
    case 'rebanada':
    case 'rebanadas':
      return _KnownUnit.slice;
    case 'g':
    case 'gramo':
    case 'gramos':
      return _KnownUnit.gram;
    case 'ml':
    case 'mililitro':
    case 'mililitros':
      return _KnownUnit.milliliter;
  }
  return null;
}

String _unitWord(_KnownUnit unit, AppLocalizations l10n, num? count) {
  final n = count ?? 1;
  return switch (unit) {
    _KnownUnit.unit => l10n.nutritionUnitNameUnit(n),
    _KnownUnit.serving => l10n.nutritionUnitNameServing(n),
    _KnownUnit.cup => l10n.nutritionUnitNameCup(n),
    _KnownUnit.tablespoon => l10n.nutritionUnitNameTablespoon(n),
    _KnownUnit.slice => l10n.nutritionUnitNameSlice(n),
    _KnownUnit.gram => 'g',
    _KnownUnit.milliliter => 'ml',
  };
}

/// Nombre de la unidad sin la cantidad, en minúsculas y en el idioma de la
/// app: "1 UNIDAD" → "unidad" / "unit"; también entiende texto suelto de la
/// BD vieja ("unidad", "Gramos" → "g"). Con [count] distinto de 1 devuelve el
/// plural ("units"); sin [count] el singular. Una unidad que no conoce (ej.
/// "2 grandes") se devuelve tal cual, sin la cantidad y en minúsculas.
String unitName(String rawUnit, AppLocalizations l10n, {num? count}) {
  final known = _knownUnit(rawUnit);
  if (known == null) return _bareUnit(rawUnit);
  return _unitWord(known, l10n, count);
}

/// Formatea [quantity] + [unit] para mostrarlos juntos sin redundancias.
/// Si la unidad ya empieza con la cantidad (ej. "1 UNIDAD" con quantity 1),
/// se omite la cantidad para no duplicar.
String formatQuantityWithUnit(
  double quantity,
  String unit,
  AppLocalizations l10n,
) {
  final amount = quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toString();
  switch (unit.trim().toUpperCase()) {
    case '1 UNIDAD':
      return l10n.nutritionCountUnit(quantity, amount);
    case '1 PORCIÓN':
      return l10n.nutritionCountServing(quantity, amount);
    case '1 TAZA':
      return l10n.nutritionCountCup(quantity, amount);
    case '1 CUCHARADA':
      return l10n.nutritionCountTablespoon(quantity, amount);
    case '1 REBANADA':
      return l10n.nutritionCountSlice(quantity, amount);
  }
  return '$amount ${prettyUnitLabel(unit, l10n)}';
}
