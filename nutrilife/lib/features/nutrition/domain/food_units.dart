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
