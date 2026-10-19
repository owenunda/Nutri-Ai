import 'package:flutter/widgets.dart';

/// Espacio que debe dejar abajo una hoja (bottom sheet): el teclado si está
/// abierto y, si no, la barra de navegación de Android. La app va borde a
/// borde, así que sin esto el botón de la hoja queda debajo de esa barra.
///
/// Con el teclado arriba Flutter ya no cuenta la barra en `padding`, así que
/// la suma nunca reserva el espacio dos veces.
double sheetBottomInset(BuildContext context) =>
    MediaQuery.viewInsetsOf(context).bottom +
    MediaQuery.paddingOf(context).bottom;
