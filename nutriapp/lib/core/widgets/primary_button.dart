import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Boton principal de la aplicacion.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,

    /// Texto que se muestra dentro del botón.
    required this.textButton,

    /// Ancho fijo del botón. Si es null, se ajusta al contenido.
    this.width,

    /// Altura del botón.
    this.height = 56,

    /// Icono que aparece a la derecha del texto.
    this.icon = Icons.arrow_forward,

    /// Tamaño del icono en píxeles.
    this.iconSize = 20,

    /// Tamaño de la fuente del texto.
    this.textSize = 16,

    /// Espacio horizontal entre el texto y el icono.
    this.spacing = 8,

    /// Color inicial (arriba) del degradado de fondo. Si es null, usa AppTheme.primaryStart.
    this.startColor,

    /// Color final (abajo) del degradado de fondo. Si es null, usa AppTheme.primaryEnd.
    this.endColor,

    /// Color del texto y del icono. Si es null, usa el color onPrimary del tema.
    this.foregroundColor,

    /// Callback que se ejecuta al presionar el botón.
    this.onPressed,
  });

  final String textButton;
  final double? width;
  final double height;
  final IconData icon;
  final double iconSize;
  final double textSize;
  final double spacing;
  final Color? startColor;
  final Color? endColor;
  final Color? foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Obtener los colores del tema actual o usar los valores del constructor
    final theme = Theme.of(context);
    
    final activeStartColor = startColor ?? theme.colorScheme.primary;
    final activeEndColor = endColor ?? AppTheme.primaryEnd;
    final activeForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          textButton,
          style: TextStyle(
            color: activeForegroundColor,
            fontSize: textSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            height: 1,
          ),
        ),
        SizedBox(width: spacing),
        Icon(icon, size: iconSize, color: activeForegroundColor),
      ],
    );

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [activeStartColor, activeEndColor],
      ),
      borderRadius: BorderRadius.circular(999),
      boxShadow: [
        BoxShadow(
          color: activeStartColor.withValues(alpha: 0.35),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
        BoxShadow(
          color: activeStartColor.withValues(alpha: 0.15),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );

    // Boton con ancho fijo.
    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Boton que se ajusta al contenido.
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

