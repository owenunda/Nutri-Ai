import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/resend_code_button.dart';
import 'verify_email_screen.dart';

/// Segundo paso de "olvidé mi contraseña": el código enviado al correo y la
/// contraseña nueva. Al guardar devuelve el correo a la pantalla anterior.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, this.repository});

  final String email;
  final AuthRepository? repository;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await _authRepository.resetPassword(
        widget.email,
        _codeController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(widget.email);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await _authRepository.forgotPassword(widget.email);
      if (mounted) setState(() => _infoMessage = 'Te enviamos un código nuevo.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: 'Nueva contraseña',
      subtitle:
          'Si ${widget.email} tiene una cuenta, te enviamos un código de 6 '
          'dígitos. Escríbelo y elige tu contraseña nueva.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFieldLabel('CÓDIGO'),
            const SizedBox(height: 10),
            AuthCodeField(controller: _codeController, enabled: !_isSubmitting),
            const SizedBox(height: 18),
            const AuthFieldLabel('CONTRASEÑA NUEVA'),
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
            if (_infoMessage != null) ...[
              const SizedBox(height: 16),
              AuthInfoText(_infoMessage!),
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
              child: ResendCodeButton(
                onResend: _resend,
                enabled: !_isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
