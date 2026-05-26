import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores principales (Nutri-Ai verde)
  static const Color primaryStart = Color(0xFF0A6B3F);
  static const Color primaryEnd = Color(0xFF1B7D50);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Colores de fondo y superficies
  static const Color background = Color(0xFFF4F9F6);
  static const Color surface = Color(0xFFFFFFFF);

  // Tema de Flutter configurado con estos colores
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStart,
        primary: primaryStart,
        onPrimary: onPrimary,
        background: background,
        surface: surface,
      ),
      // Definición personalizada para los botones elevados e interactivos
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
