import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Botón "Continuar con Google" del login y del registro.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF0F3F4),
          foregroundColor: const Color(0xFF2C2F31),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Semantics(
          label: 'Continuar con Google',
          excludeSemantics: true,
          child: SvgPicture.asset(
            'assets/images/google_wordmark.svg',
            height: 20,
          ),
        ),
      ),
    );
  }
}
