import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_form_widgets.dart';
import 'reset_password_screen.dart';

/// Primer paso de "olvidé mi contraseña": pide el correo y envía un código.
/// Devuelve el correo cuando la contraseña se cambió, para escribirlo en el
/// login.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail, this.repository});

  final String? initialEmail;
  final AuthRepository? repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.forgotPassword(email);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final changedEmail = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(email: email, repository: widget.repository),
        ),
      );
      if (changedEmail != null && mounted) {
        Navigator.of(context).pop(changedEmail);
      }
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
      title: 'Recupera tu contraseña',
      subtitle:
          'Escribe el correo de tu cuenta y te enviaremos un código para '
          'crear una contraseña nueva.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFieldLabel('CORREO ELECTRÓNICO'),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              hintText: '',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !_isSubmitting,
              onFieldSubmitted: (_) => _sendCode(),
              validator: validateEmail,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AuthErrorText(_errorMessage!),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              textButton: _isSubmitting ? 'Enviando...' : 'Enviar código',
              width: double.infinity,
              height: 56,
              icon: _isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: AuthPalette.primary,
              endColor: AuthPalette.primaryDark,
              onPressed: _isSubmitting ? null : _sendCode,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text(
                  'Volver',
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
