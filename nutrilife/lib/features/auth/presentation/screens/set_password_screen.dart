import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_form_widgets.dart';

/// Se muestra tras el primer login con Google de una cuenta sin contraseña:
/// le ofrece crear una para poder entrar también con su correo.
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({
    super.key,
    required this.nextScreen,
    this.repository,
  });

  /// Pantalla a la que se sigue al guardar o al tocar "Ahora no".
  final Widget Function() nextScreen;
  final AuthRepository? repository;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen()),
      (route) => false,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.setPassword(_passwordController.text);
      if (!mounted) return;
      _continue();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: 'Crea tu contraseña',
      subtitle:
          '¡Ya estás dentro! Si quieres, crea una contraseña para '
          'entrar también con tu correo cuando no tengas Google a mano.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFieldLabel('CONTRASEÑA'),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _passwordController,
              icon: Icons.lock_outline_rounded,
              hintText: '',
              obscureText: _obscurePassword,
              trailingIcon: _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onTrailingTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
              validator: validateNewPassword,
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('CONFIRMAR'),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _confirmPasswordController,
              icon: Icons.verified_user_outlined,
              hintText: '',
              obscureText: _obscureConfirmPassword,
              trailingIcon: _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onTrailingTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isSubmitting,
              onFieldSubmitted: (_) => _save(),
              validator: (value) =>
                  validatePasswordConfirmation(value, _passwordController.text),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AuthErrorText(_errorMessage!),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              textButton: _isSubmitting ? 'Guardando...' : 'Guardar contraseña',
              width: double.infinity,
              height: 56,
              icon: _isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: AuthPalette.primary,
              endColor: AuthPalette.primaryDark,
              onPressed: _isSubmitting ? null : _save,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : _continue,
                child: const Text(
                  'Ahora no',
                  style: TextStyle(
                    color: AuthPalette.body,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
