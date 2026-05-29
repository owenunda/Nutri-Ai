import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBCEED9).withValues(alpha: 0.32),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 760;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isCompact ? 8 : 14),
                      _BrandHeader(logoSize: isCompact ? 78 : 88),
                      SizedBox(height: isCompact ? 16 : 22),
                      _LoginPanel(isCompact: isCompact),
                      SizedBox(height: isCompact ? 16 : 20),
                      _CreateAccountPrompt(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.logoSize});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryStart.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/nutriai_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'NutriAI',
          style: TextStyle(
            color: Color(0xFF2C2F31),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu camino inteligente hacia el bienestar.',
          style: TextStyle(
            color: const Color(0xFF595C5E).withValues(alpha: 0.76),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, isCompact ? 24 : 28, 28, 26),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2A24).withValues(alpha: 0.05),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenido de nuevo',
            style: TextStyle(
              color: Color(0xFF2C2F31),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus credenciales para acceder a\ntu espacio de bienestar.',
            style: TextStyle(
              color: const Color(0xFF595C5E).withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isCompact ? 20 : 24),
          const _FieldLabel('CORREO ELECTRONICO'),
          const SizedBox(height: 9),
          const _LoginInput(
            hintText: 'name@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: isCompact ? 16 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel('CONTRASENA'),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Olvidaste tu contrasena?',
                  style: TextStyle(
                    color: AppTheme.primaryStart,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const _LoginInput(
            hintText: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            suffixIcon: Icons.visibility_outlined,
          ),
          SizedBox(height: isCompact ? 18 : 22),
          PrimaryButton(
            textButton: 'Iniciar sesion',
            width: double.infinity,
            height: isCompact ? 52 : 56,
            textSize: 15,
            iconSize: 18,
            onPressed: () {},
          ),
          SizedBox(height: isCompact ? 22 : 26),
          Center(
            child: Text(
              'O CONTINUA CON',
              style: TextStyle(
                color: const Color(0xFF595C5E).withValues(alpha: 0.72),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 18 : 22),
          Row(
            children: const [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  iconText: 'G',
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  icon: Icons.apple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF2C2F31).withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.hintText,
    required this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  final String hintText;
  final IconData icon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF2C2F31),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEFF3F5),
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF595C5E).withValues(alpha: 0.66),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF595C5E).withValues(alpha: 0.72),
          size: 20,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: const Color(0xFF595C5E).withValues(alpha: 0.72),
                size: 20,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: AppTheme.primaryStart.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    this.icon,
    this.iconText,
  });

  final String label;
  final IconData? icon;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF0F3F4),
          foregroundColor: const Color(0xFF2C2F31),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 17, color: const Color(0xFF2C2F31)),
            if (iconText != null)
              Text(
                iconText!,
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No tienes una cuenta?',
          style: TextStyle(
            color: const Color(0xFF2C2F31).withValues(alpha: 0.78),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Crea una cuenta',
            style: TextStyle(
              color: AppTheme.primaryStart,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
