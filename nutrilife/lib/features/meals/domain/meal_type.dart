import '../../../core/l10n/l10n.dart';

enum MealType {
  breakfast('BREAKFAST', 'desayuno', '🥑'),
  lunch('LUNCH', 'almuerzo', '🥗'),
  dinner('DINNER', 'cena', '🍽️'),
  snack('SNACK', 'snack', '🍎');

  const MealType(this.apiValue, this.recipeCode, this.emoji);

  /// Valor que se manda y se recibe del backend.
  final String apiValue;

  /// Tipo de comida como lo escribe el chef en las recetas (siempre en
  /// español, sin importar el idioma de la app).
  final String recipeCode;
  final String emoji;

  /// Nombre para mostrar, en el idioma de la app.
  String label(AppLocalizations l10n) => switch (this) {
        MealType.breakfast => l10n.mealsTypeBreakfast,
        MealType.lunch => l10n.mealsTypeLunch,
        MealType.dinner => l10n.mealsTypeDinner,
        MealType.snack => l10n.mealsTypeSnack,
      };

  static MealType fromApi(String? value) => MealType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => MealType.snack,
      );

  /// Comida que toca según la hora local.
  static MealType forTime(DateTime time) {
    if (time.hour < 11) return MealType.breakfast;
    if (time.hour < 16) return MealType.lunch;
    return MealType.dinner;
  }
}
