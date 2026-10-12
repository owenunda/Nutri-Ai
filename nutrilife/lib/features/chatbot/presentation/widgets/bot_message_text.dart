import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Texto de una respuesta del bot. El flujo de n8n devuelve markdown ligero
/// (negritas, listas y párrafos), así que se pinta con ese formato.
class BotMessageText extends StatelessWidget {
  final String text;

  const BotMessageText({super.key, required this.text});

  static const _base = TextStyle(
    color: Color(0xFF2C2F31),
    fontSize: 15,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      // Sin esto, un salto de línea simple se pierde y las frases se pegan.
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: _base,
        strong: const TextStyle(fontWeight: FontWeight.w700),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: _base.copyWith(
          color: const Color(0xFF0A6B3F),
          fontWeight: FontWeight.w700,
        ),
        listIndent: 20,
        blockSpacing: 8,
      ),
    );
  }
}
