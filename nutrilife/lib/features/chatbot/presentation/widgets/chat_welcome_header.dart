import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';

class ChatWelcomeHeader extends StatelessWidget {
  const ChatWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Icono Central de la IA
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFEDEFF1), Color(0xFFD8DCE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/nutria_sentada.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Welcome Text
        Text(
          context.l10n.chatWelcomeTitle,
          style: const TextStyle(
            color: Color(0xFF2C2F31), // on_surface per DESIGN.md
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.chatWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
