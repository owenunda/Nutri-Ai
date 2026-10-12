enum MealType {
  breakfast('BREAKFAST', 'Desayuno', '🥑'),
  lunch('LUNCH', 'Almuerzo', '🥗'),
  dinner('DINNER', 'Cena', '🍽️'),
  snack('SNACK', 'Snack', '🍎');

  const MealType(this.apiValue, this.label, this.emoji);

  final String apiValue;
  final String label;
  final String emoji;

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
