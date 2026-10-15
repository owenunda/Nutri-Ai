import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../legal/data/legal_documents.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../google_sign_in_flow.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/google_sign_in_button.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.repository});

  final AuthRepository? repository;

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

  late final AuthRepository _authRepository =
      widget.repository ?? AuthRepository();

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocuments.terms);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLegalDocument(context, LegalDocuments.privacy);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
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
      _showSnackBar(context.l10n.authTermsRequired, isWarning: true);
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

      if (!mounted) return;

      // La cuenta queda sin verificar: el backend envió un código al correo y
      // la sesión empieza al verificarlo. "Volver" desde ahí lleva al login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              VerifyEmailScreen(email: _emailController.text.trim()),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.message,
        isDuplicate: error.code == 'EMAIL_ALREADY_EXISTS',
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(context.l10n.authErrorRegister);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    FocusScope.of(context).unfocus();

    // Registrarse con Google también crea una cuenta: mismos términos.
    if (!_acceptedTerms) {
      _showSnackBar(context.l10n.authTermsRequired, isWarning: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final error = await signInWithGoogle(
      context,
      repository: _authRepository,
    );
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });
    if (error != null) {
      _showSnackBar(error);
    }
  }

  /// El tipo de aviso lo decide quien llama (no el texto del mensaje, que
  /// cambia con el idioma): [isDuplicate] si el correo ya existe, [isWarning]
  /// si falta aceptar los términos.
  void _showSnackBar(
    String message, {
    bool isDuplicate = false,
    bool isWarning = false,
  }) {
    final l10n = context.l10n;

    final Color accentColor = isDuplicate || isWarning
        ? const Color(0xFFD97706)
        : const Color(0xFFB42318);

    final IconData icon = isDuplicate
        ? Icons.mark_email_unread_rounded
        : isWarning
        ? Icons.warning_amber_rounded
        : Icons.error_outline_rounded;

    final String title = isDuplicate
        ? l10n.authRegisterSnackDuplicateTitle
        : isWarning
        ? l10n.authRegisterSnackWarningTitle
        : l10n.authRegisterSnackErrorTitle;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuthPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E2A24).withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AuthPalette.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: AuthPalette.body.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                            termsTap: _termsTap,
                            privacyTap: _privacyTap,
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
                            onGoogleSignUp: _signUpWithGoogle,
                            onLoginTap: () => Navigator.pop(context),
                          ),

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
    required this.termsTap,
    required this.privacyTap,
    required this.onToggleTerms,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
    required this.onSubmit,
    required this.onGoogleSignUp,
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

  final GestureRecognizer termsTap;
  final GestureRecognizer privacyTap;

  final VoidCallback onToggleTerms;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignUp;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
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
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.authRegisterTitle,
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

            Text(
              context.l10n.authRegisterSubtitle,
              style: TextStyle(
                color: AuthPalette.subtitle,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 26),

            AuthFieldLabel(context.l10n.authRegisterNameLabel),

            const SizedBox(height: 10),

            AuthTextField(
              controller: nameController,
              icon: Icons.person_outline_rounded,
              hintText: '',
              keyboardType: TextInputType.name,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.authNameRequired;
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            AuthFieldLabel(context.l10n.authEmailLabel),

            const SizedBox(height: 10),

            AuthTextField(
              controller: emailController,
              icon: Icons.mail_outline_rounded,
              hintText: '',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isSubmitting,
              validator: (value) => validateEmail(context.l10n, value),
            ),

            const SizedBox(height: 18),

            AuthFieldLabel(context.l10n.authPasswordLabel),

            const SizedBox(height: 10),

            AuthTextField(
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
              validator: (value) => validateNewPassword(context.l10n, value),
            ),

            const SizedBox(height: 18),

            AuthFieldLabel(context.l10n.authConfirmLabel),

            const SizedBox(height: 10),

            AuthTextField(
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
              validator: (value) => validatePasswordConfirmation(
                context.l10n,
                value,
                passwordController.text,
              ),
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
                          ? AuthPalette.primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      border: Border.all(
                        color: acceptedTerms
                            ? AuthPalette.primary
                            : AuthPalette.outline,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: acceptedTerms
                          ? AuthPalette.primary
                          : Colors.transparent,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: AuthPalette.body,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: context.l10n.authRegisterTermsPrefix),
                          TextSpan(
                            text: context.l10n.authTermsOfService,
                            recognizer: termsTap,
                            style: const TextStyle(
                              color: AuthPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: context.l10n.authTermsAnd),
                          TextSpan(
                            text: context.l10n.authPrivacyPolicy,
                            recognizer: privacyTap,
                            style: const TextStyle(
                              color: AuthPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              textButton: isSubmitting
                  ? context.l10n.authRegisterSubmitting
                  : context.l10n.authRegisterSubmit,
              width: double.infinity,
              height: 56,
              icon: isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              iconSize: 20,
              textSize: 16,
              startColor: AuthPalette.primary,
              endColor: AuthPalette.primaryDark,
              onPressed: isSubmitting ? null : onSubmit,
            ),

            const SizedBox(height: 22),

            Center(
              child: Text(
                context.l10n.authRegisterOrSignUpWith,
                style: TextStyle(
                  color: AuthPalette.body.withValues(alpha: 0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 16),

            GoogleSignInButton(
              onPressed: isSubmitting ? null : onGoogleSignUp,
            ),

            const SizedBox(height: 20),

            Container(
              height: 1,
              decoration: BoxDecoration(
                color: AuthPalette.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.authRegisterHaveAccount,
                  style: TextStyle(
                    color: AuthPalette.body.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 6),

                GestureDetector(
                  onTap: onLoginTap,
                  child: Text(
                    context.l10n.authRegisterSignIn,
                    style: TextStyle(
                      color: AuthPalette.primary,
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
