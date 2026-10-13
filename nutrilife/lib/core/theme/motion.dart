import 'package:flutter/material.dart';

/// Movimiento de las hojas que suben desde abajo: entran frenando suave y
/// salen un poco más rápido para que cerrar se sienta ágil.
const AnimationStyle kSheetAnimation = AnimationStyle(
  duration: Duration(milliseconds: 420),
  reverseDuration: Duration(milliseconds: 280),
  curve: Curves.easeOutQuart,
  reverseCurve: Curves.easeInCubic,
);

/// Cuando el contenido de una hoja cambia de alto (pestañas, búsqueda,
/// errores), el alto se acomoda con esta duración y curva.
const Duration kResizeDuration = Duration(milliseconds: 260);
const Curve kResizeCurve = Curves.easeOutCubic;
