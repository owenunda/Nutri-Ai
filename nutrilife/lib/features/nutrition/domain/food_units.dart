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
  // Si el valor no está en la lista (ej. unidades viejas de la BD), al
  // menos capitalizamos la primera letra para que se vea mejor.
  if (normalized.isEmpty) return normalized;
  return normalized[0].toUpperCase() + normalized.substring(1);
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
