import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../legal/data/legal_documents.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';
import '../google_sign_in_flow.dart';
import '../widgets/google_sign_in_button.dart';
import 'auth_flow_navigator.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

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

                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,

                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),

                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 8 : 14),

                            _BrandHeader(logoSize: isCompact ? 78 : 88),

                            SizedBox(height: isCompact ? 16 : 22),

                            Flexible(child: _LoginPanel(isCompact: isCompact)),

                            SizedBox(height: isCompact ? 10 : 12),

                            _CreateAccountPrompt(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                            ),

                            // TODO: remove — solo para previsualizar onboarding
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AuthFlowNavigator(),
                                ),
                              ),
                              child: const Text(
                                'Ver onboarding',
                                style: TextStyle(fontSize: 11, color: Color(0xFFADB5BD)),
                              ),
                            ),

                            SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? 24
                                  : 40,
                            ),
                          ],
                        ),
                      ),
                    ),
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
        SizedBox(
          width: logoSize,
          height: logoSize,

          child: Image.asset(
            'assets/images/nutria_comiendo2.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'NutriLife',
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

class _LoginPanel extends StatefulWidget {
  const _LoginPanel({required this.isCompact});

  final bool isCompact;

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  late final TextEditingController _emailController;

  late final TextEditingController _passwordController;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocuments.terms);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocuments.privacy);

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();

    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Si sale bien, navega y este panel desaparece; si el usuario cierra el
    // selector, error es null y solo se quita la carga.
    final error = await signInWithGoogle(context);
    if (!mounted) return;
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
  }

  /// Al volver con la contraseña cambiada, deja el correo escrito para entrar.
  Future<void> _openForgotPassword() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
    if (email == null || !mounted) return;

    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await SessionService.save(
          token: result['token'] as String,
          user: result['user'] as Map<String, dynamic>,
        );

        if (!mounted) return;
        openAppAfterLogin(
          context,
          result['user'] as Map<String, dynamic>,
          needsProfileSetup: result['needsProfileSetup'] == true,
        );

        return;
      }

      final error = result['error'];
      if (error is Map && error['code'] == 'EMAIL_NOT_VERIFIED') {
        // El backend ya envió un código nuevo al correo.
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                VerifyEmailScreen(email: _emailController.text.trim()),
          ),
        );
        return;
      }

      setState(() {
        _errorMessage = result['message'] ?? 'Login failed';

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,

          padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),

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

          child: SingleChildScrollView(
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
                  'Ingresa tus credenciales para acceder a tu espacio de bienestar.',
                  style: TextStyle(
                    color: const Color(0xFF595C5E).withValues(alpha: 0.78),

                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                const _FieldLabel('CORREO ELECTRONICO'),

                const SizedBox(height: 9),

                _LoginInput(
                  hintText: 'name@example.com',

                  icon: Icons.mail_outline_rounded,

                  keyboardType: TextInputType.emailAddress,

                  controller: _emailController,

                  enabled: !_isLoading,
                ),

                const SizedBox(height: 18),

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

                _LoginInput(
                  hintText: '••••••••',

                  icon: Icons.lock_outline_rounded,

                  obscureText: !_isPasswordVisible,

                  controller: _passwordController,

                  enabled: !_isLoading,

                  suffixIcon: _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,

                  onSuffixPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _openForgotPassword,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AppTheme.primaryStart,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),

                      borderRadius: BorderRadius.circular(8),

                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),

                    child: Text(
                      _errorMessage!,

                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                PrimaryButton(
                  textButton: _isLoading ? 'Iniciando...' : 'Iniciar sesion',

                  width: double.infinity,
                  height: 56,
                  textSize: 15,
                  iconSize: 18,

                  onPressed: _isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: 26),

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

                const SizedBox(height: 22),

                // Login con Apple retirado temporalmente.
                GoogleSignInButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                ),

                const SizedBox(height: 12),

                // Entrar con Google puede crear una cuenta nueva: se avisa de
                // los términos sin agregar un paso.
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: const Color(0xFF595C5E).withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Al continuar con Google aceptas los '),
                      TextSpan(
                        text: 'Términos del Servicio',
                        recognizer: _termsTap,
                        style: const TextStyle(
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' y la '),
                      TextSpan(
                        text: 'Política de Privacidad',
                        recognizer: _privacyTap,
                        style: const TextStyle(
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),

                borderRadius: BorderRadius.circular(34),
              ),

              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryStart,
                  ),
                ),
              ),
            ),
          ),
      ],
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
    this.controller,
    this.enabled = true,
    this.onSuffixPressed,
  });

  final String hintText;
  final IconData icon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool enabled;
  final VoidCallback? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
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
            : GestureDetector(
                onTap: onSuffixPressed,

                child: Icon(
                  suffixIcon,
                  color: const Color(0xFF595C5E).withValues(alpha: 0.72),

                  size: 20,
                ),
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

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Text(
          'No tienes una cuenta? ',

          style: TextStyle(
            color: const Color(0xFF595C5E).withValues(alpha: 0.76),

            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        GestureDetector(
          onTap: onTap,

          child: const Text(
            'Crea una',

            style: TextStyle(
              color: AppTheme.primaryStart,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
