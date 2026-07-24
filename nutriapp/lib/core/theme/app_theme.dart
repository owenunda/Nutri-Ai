import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores principales (Nutri-Ai verde)
  static const Color primaryStart = Color(0xFF0A6B3F);
  static const Color primaryEnd = Color(0xFF1B7D50);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Colores de fondo y superficies
  static const Color background = Color(0xFFF4F9F6);
  static const Color surface = Color(0xFFFFFFFF);

  // Tokens del sistema de diseño "The Mindful Alchemist" (docs/DESIGN.md)
  static const Color onSurface = Color(0xFF2C2F31);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color tertiary = Color(0xFF006573);
  static const Color primaryContainer = Color(0xFFD5F6E5);
  static const Color surfaceContainerLow = Color(0xFFEFF3F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  static const double radiusMd = 24;
  static const double radiusLg = 32;

  static const List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: Color(0x0F2C2F31),
      offset: Offset(0, 20),
      blurRadius: 40,
    ),
  ];

  // Tema de Flutter configurado con estos colores
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStart,
        primary: primaryStart,
        onPrimary: onPrimary,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(),
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
