import 'package:flutter/material.dart';

/// Cierra el teclado al tocar fuera de un campo de texto. En iOS el teclado
/// no trae botón para ocultarse, y en los campos multilínea el Enter solo
/// agrega una línea, así que sin esto no hay forma de bajarlo.
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  const DismissKeyboardOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // translucent: los toques siguen llegando a botones y listas de abajo.
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
