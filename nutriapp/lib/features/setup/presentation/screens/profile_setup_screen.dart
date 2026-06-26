import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import 'goal_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.userName});

  final String? userName;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedSex;
  bool _isSaving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double get _progress {
    final completed = <bool>[
      _isValidAge(_ageController.text),
      _isValidValue(_weightController.text),
      _isValidValue(_heightController.text),
      _selectedSex != null,
    ].where((value) => value).length;

    return completed / 4.0;
  }

  bool _isValidAge(String value) {
    final age = int.tryParse(value.trim());
    return age != null && age >= 16 && age <= 120;
  }

  bool _isValidValue(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed > 0;
  }

  String? _validateAge(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'La edad es obligatoria.';
    }

    final age = int.tryParse(text);
    if (age == null) {
      return 'Ingresa una edad válida.';
    }

    if (age < 16) {
      return 'Debes tener al menos 16 años.';
    }

    if (age > 120) {
      return 'Ingresa una edad válida.';
    }

    return null;
  }

  String? _validateNumber(String? value, String label) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El $label es obligatorio.';
    }

    final normalized = text.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un $label válido.';
    }

    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _selectedSex == null) {
      if (_selectedSex == null) {
        _showSnackBar('Selecciona tu sexo para continuar.');
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GoalSetupScreen(userName: widget.userName),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    final lowerMessage = message.toLowerCase();
    final isSuccess = lowerMessage.contains('guardado');
    final isWarning = lowerMessage.contains('sexo');

    final Color accentColor = isSuccess
        ? AppTheme.primaryStart
        : isWarning
            ? const Color(0xFFD97706)
            : const Color(0xFFB42318);

    final IconData icon = isSuccess
        ? Icons.check_circle_rounded
        : isWarning
            ? Icons.info_outline_rounded
            : Icons.error_outline_rounded;

    final String title = isSuccess ? 'Perfil listo' : 'Falta un dato';

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.16),
            ),
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
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22,
                ),
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
                        color: const Color(0xFF2C2F31),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: const Color(0xFF59606A).withValues(alpha: 0.95),
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
    final progressPercent = (_progress * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -40,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.12),
              size: 140,
            ),
          ),
          Positioned(
            top: 88,
            left: 96,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 70,
            ),
          ),
          Positioned(
            top: 150,
            left: 156,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 110,
            ),
          ),
          Positioned(
            top: 380,
            right: -10,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 80,
            ),
          ),
          Positioned(
            bottom: 180,
            left: 160,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 52,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'NutriAI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.primaryStart,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Completa tu perfil',
                        style: TextStyle(
                          color: Color(0xFF2C2F31),
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estos datos nos ayudan a personalizar tu\nplan nutricional.',
                        style: TextStyle(
                          color: const Color(0xFF595C5E).withValues(alpha: 0.92),
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldBlock(
                              label: 'EDAD',
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (_) => setState(() {}),
                                validator: _validateAge,
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.calendar_month_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldBlock(
                              label: 'PESO (KG)',
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    _validateNumber(value, 'peso'),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.monitor_weight_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldBlock(
                              label: 'ALTURA (CM)',
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    _validateNumber(value, 'altura'),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.height_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldBlock(
                              label: 'SEXO',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _SexOption(
                                      label: 'Hombre',
                                      selected: _selectedSex == 'Hombre',
                                      onTap: () {
                                        setState(() {
                                          _selectedSex = 'Hombre';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _SexOption(
                                      label: 'Mujer',
                                      selected: _selectedSex == 'Mujer',
                                      onTap: () {
                                        setState(() {
                                          _selectedSex = 'Mujer';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFF6EA),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Precisión NutriAI',
                                          style: TextStyle(
                                            color: AppTheme.primaryStart,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tu metabolismo basal se calculará\nautomáticamente.',
                                          style: TextStyle(
                                            color: const Color(0xFF2C2F31)
                                                .withValues(alpha: 0.76),
                                            fontSize: 13,
                                            height: 1.25,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PROGRESO DE REGISTRO',
                                  style: TextStyle(
                                    color: const Color(0xFF595C5E)
                                        .withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                Text(
                                  '$progressPercent%',
                                  style: const TextStyle(
                                    color: AppTheme.primaryStart,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: _progress),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 10,
                                    backgroundColor: const Color(0xFFDDE4E8),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryStart,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                            PrimaryButton(
                              textButton:
                                  _isSaving ? 'Guardando...' : 'Guardar perfil',
                              width: double.infinity,
                              height: 58,
                              icon: _isSaving
                                  ? Icons.hourglass_top_rounded
                                  : Icons.arrow_forward_rounded,
                              iconSize: 20,
                              onPressed: _isSaving ? null : _saveProfile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F3F5),
      prefixIcon: Icon(
        prefixIcon,
        color: AppTheme.primaryStart,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: AppTheme.primaryStart.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF595C5E).withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SexOption extends StatelessWidget {
  const _SexOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF68E3A0) : const Color(0xFFF0F3F5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF0A6B3F)
                  : const Color(0xFF2C2F31).withValues(alpha: 0.72),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
