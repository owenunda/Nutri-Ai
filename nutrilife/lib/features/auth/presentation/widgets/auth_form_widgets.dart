import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colores de las pantallas de registro y creación de contraseña.
class AuthPalette {
  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color title = Color(0xFF2C2F31);

  static const Color body = Color(0xFF595C5E);

  static const Color subtitle = Color(0xFF595C5E);

  static const Color label = Color(0xFF6B7280);

  static const Color hint = Color(0xFF97A0AA);

  static const Color icon = Color(0xFF78808A);

  static const Color outline = Color(0xFFD7DEE5);

  static const Color divider = Color(0xFFE7ECF0);

  static const Color fieldFill = Color(0xFFEFF3F5);

  static const Color primary = Color(0xFF0A6B3F);

  static const Color primaryDark = Color(0xFF085531);

  static const Color primarySoft = Color(0xFFDDF3E8);
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AuthPalette.label,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.trailingIcon,
    this.onTrailingTap,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        color: AuthPalette.title,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AuthPalette.fieldFill,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AuthPalette.hint,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AuthPalette.icon, size: 20),
        suffixIcon: trailingIcon == null
            ? null
            : IconButton(
                onPressed: enabled ? onTrailingTap : null,
                icon: Icon(
                  trailingIcon,
                  color: AuthPalette.icon,
                  size: 20,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AuthPalette.primary.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class AuthGlowCircle extends StatelessWidget {
  const AuthGlowCircle({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Validaciones de contraseña compartidas por el registro y la creación de
/// contraseña tras entrar con Google.
String? validateNewPassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return 'La contraseña es obligatoria.';
  }

  if (password.length < 6) {
    return 'La contraseña debe tener al menos 6 caracteres.';
  }

  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  final confirmPassword = value ?? '';

  if (confirmPassword.isEmpty) {
    return 'Confirma tu contraseña.';
  }

  if (confirmPassword != password) {
    return 'Las contraseñas no coinciden.';
  }

  return null;
}
