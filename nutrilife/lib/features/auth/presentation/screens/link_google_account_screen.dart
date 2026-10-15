import 'package:flutter/material.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../google_sign_in_flow.dart';
import '../widgets/auth_form_widgets.dart';
import 'forgot_password_screen.dart';

/// Se abre cuando alguien entra con Google y su correo ya tiene una cuenta con
/// contraseña: la pide para vincular Google sin perder ninguna de las dos
/// formas de entrar.
class LinkGoogleAccountScreen extends StatefulWidget {
  const LinkGoogleAccountScreen({
    super.key,
    required this.idToken,
    this.repository,
    this.onLinked = _openApp,
  });

  /// idToken de Google del intento de login, todavía válido (~1 hora).
  final String idToken;
  final AuthRepository? repository;

  /// Qué hacer con la sesión una vez vinculada. Por defecto la guarda y abre
  /// la app.
  final void Function(BuildContext context, GoogleLoginResult result) onLinked;

  static Future<void> _openApp(
    BuildContext context,
    GoogleLoginResult result,
  ) async {
    await SessionService.save(token: result.token, user: result.user);
    if (!context.mounted) return;
    openAppAfterLogin(
      context,
      result.user,
      needsProfileSetup: result.needsProfileSetup,
    );
  }

  @override
  State<LinkGoogleAccountScreen> createState() =>
      _LinkGoogleAccountScreenState();
}

class _LinkGoogleAccountScreenState extends State<LinkGoogleAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final result = await _authRepository.linkGoogle(
        widget.idToken,
        _passwordController.text,
      );
      if (!mounted) return;
      widget.onLinked(context, result);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _openForgotPassword() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
    if (email == null || !mounted) return;
    setState(() {
      _errorMessage = null;
      _infoMessage = 'Contraseña actualizada. Escríbela para vincular tu cuenta.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: 'Vincula tu cuenta',
      subtitle:
          'Ya tienes una cuenta de NutriLife con este correo. Escribe tu '
          'contraseña para vincularla con Google; después podrás entrar de '
          'las dos formas.',
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
              textInputAction: TextInputAction.done,
              enabled: !_isSubmitting,
              onFieldSubmitted: (_) => _link(),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Escribe tu contraseña.'
                  : null,
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
              textButton: _isSubmitting ? 'Vinculando...' : 'Vincular',
              width: double.infinity,
              height: 56,
              icon: _isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.link_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: AuthPalette.primary,
              endColor: AuthPalette.primaryDark,
              onPressed: _isSubmitting ? null : _link,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : _openForgotPassword,
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: AuthPalette.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
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
