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
    return Scaffold(
      backgroundColor: AuthPalette.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -90,
            child: AuthGlowCircle(
              color: AuthPalette.primary.withValues(alpha: 0.10),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: AuthGlowCircle(
              color: const Color(0xFFBCEED9).withValues(alpha: 0.22),
              size: 260,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: AuthPalette.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2A24).withValues(alpha: 0.05),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Crea tu contraseña',
                    style: TextStyle(
                      color: AuthPalette.title,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/nutria_feliz.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Así también podrás entrar con tu correo, además de con Google.',
              style: TextStyle(
                color: AuthPalette.subtitle,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 26),
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
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
