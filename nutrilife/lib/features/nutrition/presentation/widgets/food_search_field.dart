import 'package:flutter/material.dart';

/// Buscador de alimentos con una X para borrar lo escrito.
class FoodSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const FoodSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(48),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Color(0xFF2C2F31),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Busca más de 100,000 alimentos...',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: controller.clear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}
