import 'package:flutter/material.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/services/auth_service.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar(
        'Debes aceptar los términos del servicio y la política de privacidad.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authRepository.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Auto login to retrieve JWT auth token
      final loginResult = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (loginResult['success'] == true) {
        DioClient.authToken = loginResult['token'];
      }

      if (!mounted) return;

      _showSnackBar('Cuenta creada correctamente. ¡Bienvenido!');

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            user: {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
            },
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('No se pudo completar el registro. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RegisterPalette.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -90,
            child: _GlowCircle(
              color: _RegisterPalette.primary.withValues(alpha: 0.10),
              size: 240,
            ),
          ),

          Positioned(
            bottom: -120,
            left: -120,
            child: _GlowCircle(
              color: const Color(0xFFBCEED9).withValues(alpha: 0.22),
              size: 260,
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RegisterCard(
                            formKey: _formKey,
                            nameController: _nameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            acceptedTerms: _acceptedTerms,
                            obscurePassword: _obscurePassword,
                            obscureConfirmPassword: _obscureConfirmPassword,
                            isSubmitting: _isSubmitting,
                            onToggleTerms: () {
                              setState(() {
                                _acceptedTerms = !_acceptedTerms;
                              });
                            },
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            onToggleConfirmVisibility: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            onSubmit: _submitRegister,
                            onLoginTap: () => Navigator.pop(context),
                          ),

                          const SizedBox(height: 22),

                          const _BrandFooter(),

                          SizedBox(
                            height: constraints.maxHeight < 760 ? 18 : 10,
                          ),
                        ],
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.acceptedTerms,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isSubmitting,
    required this.onToggleTerms,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
    required this.onSubmit,
    required this.onLoginTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final bool acceptedTerms;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isSubmitting;

  final VoidCallback onToggleTerms;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: _RegisterPalette.surface,
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
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear cuenta',
              style: TextStyle(
                color: _RegisterPalette.title,
                fontSize: 30,
                height: 1.02,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Comienza tu camino hacia una alimentación inteligente.',
              style: TextStyle(
                color: _RegisterPalette.subtitle,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 26),

            const _FieldLabel('NOMBRE COMPLETO'),

            const SizedBox(height: 10),

            _RegisterField(
              controller: nameController,
              icon: Icons.person_outline_rounded,
              hintText: '',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            const _FieldLabel('CORREO ELECTRÓNICO'),

            const SizedBox(height: 10),

            _RegisterField(
              controller: emailController,
              icon: Icons.mail_outline_rounded,
              hintText: '',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isSubmitting,
              validator: (value) {
                final email = value?.trim() ?? '';

                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                if (email.isEmpty) {
                  return 'El correo electrónico es obligatorio.';
                }

                if (!emailRegex.hasMatch(email)) {
                  return 'Ingresa un correo electrónico válido.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            const _FieldLabel('CONTRASEÑA'),

            const SizedBox(height: 10),

            _RegisterField(
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              hintText: '',
              obscureText: obscurePassword,
              trailingIcon: obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onTrailingTap: onTogglePasswordVisibility,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              enabled: !isSubmitting,
              validator: (value) {
                final password = value ?? '';

                if (password.isEmpty) {
                  return 'La contraseña es obligatoria.';
                }

                if (password.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            const _FieldLabel('CONFIRMAR'),

            const SizedBox(height: 10),

            _RegisterField(
              controller: confirmPasswordController,
              icon: Icons.verified_user_outlined,
              hintText: '',
              obscureText: obscureConfirmPassword,
              trailingIcon: obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onTrailingTap: onToggleConfirmVisibility,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              enabled: !isSubmitting,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (value) {
                final confirmPassword = value ?? '';

                if (confirmPassword.isEmpty) {
                  return 'Confirma tu contraseña.';
                }

                if (confirmPassword != passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }

                return null;
              },
            ),

            const SizedBox(height: 22),

            GestureDetector(
              onTap: isSubmitting ? null : onToggleTerms,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: acceptedTerms
                          ? _RegisterPalette.primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      border: Border.all(
                        color: acceptedTerms
                            ? _RegisterPalette.primary
                            : _RegisterPalette.outline,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: acceptedTerms
                          ? _RegisterPalette.primary
                          : Colors.transparent,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: _RegisterPalette.body,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Acepto los '),
                          TextSpan(
                            text: 'Términos del Servicio',
                            style: const TextStyle(
                              color: _RegisterPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de Privacidad.',
                            style: const TextStyle(
                              color: _RegisterPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              textButton: isSubmitting ? 'Registrando...' : 'Registrarse',
              width: double.infinity,
              height: 56,
              icon: isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: _RegisterPalette.primary,
              endColor: _RegisterPalette.primaryDark,
              onPressed: isSubmitting ? null : onSubmit,
            ),

            const SizedBox(height: 20),

            Container(
              height: 1,
              decoration: BoxDecoration(
                color: _RegisterPalette.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya tienes una cuenta?',
                  style: TextStyle(
                    color: _RegisterPalette.body.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 6),

                GestureDetector(
                  onTap: onLoginTap,
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: _RegisterPalette.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      style: const TextStyle(
        color: _RegisterPalette.label,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
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
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        color: _RegisterPalette.title,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _RegisterPalette.fieldFill,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _RegisterPalette.hint,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: _RegisterPalette.icon, size: 20),
        suffixIcon: trailingIcon == null
            ? null
            : IconButton(
                onPressed: enabled ? onTrailingTap : null,
                icon: Icon(
                  trailingIcon,
                  color: _RegisterPalette.icon,
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
            color: _RegisterPalette.primary.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: _RegisterPalette.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 20,
                  color: _RegisterPalette.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'NUTRIAI',
                  style: TextStyle(
                    color: _RegisterPalette.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text.rich(
            TextSpan(
              style: TextStyle(
                color: _RegisterPalette.title,
                fontSize: 26,
                height: 1.02,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: 'Comienza tu '),
                TextSpan(
                  text: 'viaje',
                  style: TextStyle(color: _RegisterPalette.primary),
                ),
                TextSpan(text: '\nconsciente.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

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

class _RegisterPalette {
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

  static const Color tertiary = Color(0xFF8FE3BE);
}
