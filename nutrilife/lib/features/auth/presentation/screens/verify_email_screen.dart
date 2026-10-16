import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../google_sign_in_flow.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/resend_code_button.dart';

/// Pide el código de 6 dígitos enviado al correo. Se abre al registrarse con
/// email y cuando alguien sin verificar intenta entrar (el código ya se envió).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.repository,
    this.onVerified = _openApp,
  });

  final String email;
  final AuthRepository? repository;

  /// Qué hacer con la sesión una vez verificado. Por defecto la guarda y abre
  /// la app.
  final void Function(BuildContext context, GoogleLoginResult result) onVerified;

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
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final result = await _authRepository.verifyEmail(
        widget.email,
        _codeController.text,
      );
      if (!mounted) return;
      widget.onVerified(context, result);
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
      await _authRepository.resendVerification(widget.email);
      if (mounted) setState(() => _infoMessage = context.l10n.authCodeResent);
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(
      title: context.l10n.authVerifyTitle,
      subtitle: context.l10n.authVerifySubtitle(widget.email),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthFieldLabel(context.l10n.authCodeLabel),
            const SizedBox(height: 10),
            AuthCodeField(
              controller: _codeController,
              enabled: !_isSubmitting,
              onSubmitted: _verify,
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
              textButton: _isSubmitting
                  ? context.l10n.authVerifying
                  : context.l10n.authVerifyButton,
              width: double.infinity,
              height: 56,
              icon: _isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: AuthPalette.primary,
              endColor: AuthPalette.primaryDark,
              onPressed: _isSubmitting ? null : _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: ResendCodeButton(
                onResend: _resend,
                enabled: !_isSubmitting,
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: Text(
                  context.l10n.commonBack,
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

/// Campo para el código de 6 dígitos. También lo usa restablecer contraseña.
class AuthCodeField extends StatelessWidget {
  const AuthCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      icon: Icons.pin_outlined,
      hintText: '000000',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      enabled: enabled,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      validator: (value) => (value ?? '').length == 6
          ? null
          : context.l10n.authCodeInvalid,
    );
  }
}
