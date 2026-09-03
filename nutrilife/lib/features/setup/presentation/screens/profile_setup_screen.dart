import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/setup_repository.dart';
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
  final SetupRepository _setupRepository = SetupRepository();
  final List<String> _ageOptions = List.generate(101, (index) => '$index');
  final List<String> _weightOptions = List.generate(
    76,
    (index) => '${index + 45}',
  );
  final List<String> _heightOptions = List.generate(
    101,
    (index) => (1.50 + (index / 100)).toStringAsFixed(2),
  );

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
      _isValidWeight(_weightController.text),
      _isValidHeight(_heightController.text),
      _selectedSex != null,
    ].where((value) => value).length;

    return completed / 4.0;
  }

  bool _isValidAge(String value) {
    final age = int.tryParse(value.trim());
    return age != null && age >= 16 && age <= 100;
  }

  bool _isValidWeight(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed >= 45 && parsed <= 120;
  }

  bool _isValidHeight(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed >= 1.50 && parsed <= 2.50;
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

    if (age > 100) {
      return 'Ingresa una edad válida.';
    }

    return null;
  }

  String? _validateWeight(String? value, String label) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'El peso es obligatorio.';
    }

    final normalized = text.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Ingresa un $label válido.';
    }

    if (parsed < 45 || parsed > 120) {
      return 'Selecciona un peso valido.';
    }

    return null;
  }

  String? _validateHeight(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'La altura es obligatoria.';
    }

    final normalized = text.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Ingresa una altura valida.';
    }

    if (parsed < 1.50 || parsed > 2.50) {
      return 'La altura debe estar entre 1.50 cm y 2.50 cm.';
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
      final age = int.parse(_ageController.text.trim());
      final weight = double.parse(
        _weightController.text.trim().replaceAll(',', '.'),
      );
      final heightInMeters = double.parse(
        _heightController.text.trim().replaceAll(',', '.'),
      );
      final heightInCentimeters = heightInMeters * 100;

      await _setupRepository.updateProfile(
        age: age,
        weight: weight,
        height: heightInCentimeters,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GoalSetupScreen(
            userName: widget.userName,
            age: age,
            weight: weight,
            height: heightInCentimeters,
          ),
        ),
      );
    } on SetupException catch (error) {
      if (mounted) {
        _showSnackBar(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo guardar tu perfil. Inténtalo de nuevo.');
      }
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

    final String title = isSuccess
        ? 'Perfil listo'
        : isWarning
        ? 'Falta un dato'
        : 'No se pudo guardar';

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
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
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
                        'NutriLife',
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
                          color: const Color(
                            0xFF595C5E,
                          ).withValues(alpha: 0.92),
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
                              child: _PickerField(
                                controller: _ageController,
                                icon: Icons.calendar_month_outlined,
                                options: _ageOptions,
                                unit: 'años',
                                validator: _validateAge,
                                onChanged: () => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldBlock(
                              label: 'PESO (KG)',
                              child: _PickerField(
                                controller: _weightController,
                                icon: Icons.monitor_weight_outlined,
                                options: _weightOptions,
                                unit: 'kg',
                                validator: (value) =>
                                    _validateWeight(value, 'peso'),
                                onChanged: () => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FieldBlock(
                              label: 'ALTURA (CM)',
                              child: _PickerField(
                                controller: _heightController,
                                icon: Icons.height_rounded,
                                options: _heightOptions,
                                unit: 'cm',
                                validator: _validateHeight,
                                onChanged: () => setState(() {}),
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
                                          'Precisión NutriLife',
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
                                            color: const Color(
                                              0xFF2C2F31,
                                            ).withValues(alpha: 0.76),
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
                                    color: const Color(
                                      0xFF595C5E,
                                    ).withValues(alpha: 0.85),
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
                              textButton: _isSaving
                                  ? 'Guardando...'
                                  : 'Guardar perfil',
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
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.controller,
    required this.icon,
    required this.options,
    required this.unit,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final IconData icon;
  final List<String> options;
  final String unit;
  final String? Function(String?) validator;
  final VoidCallback onChanged;

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<String> field,
  ) async {
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = option == controller.text;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(option),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryStart.withValues(alpha: 0.10)
                          : const Color(0xFFF0F3F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 32),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option,
                                style: const TextStyle(
                                  color: Color(0xFF2C2F31),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                unit,
                                style: TextStyle(
                                  color: const Color(
                                    0xFF595C5E,
                                  ).withValues(alpha: 0.75),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.primaryStart,
                                  size: 22,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedValue == null) {
      return;
    }

    controller.text = selectedValue;
    field.didChange(selectedValue);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => validator(controller.text),
      builder: (field) {
        final hasValue = controller.text.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPicker(context, field),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: field.hasError
                          ? const Color(0xFFB42318)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: AppTheme.primaryStart, size: 20),
                      Expanded(
                        child: Center(
                          child: Text(
                            hasValue ? controller.text : '',
                            style: const TextStyle(
                              color: Color(0xFF2C2F31),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: hasValue
                            ? Text(
                                unit,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: const Color(
                                    0xFF595C5E,
                                  ).withValues(alpha: 0.78),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF6B7280),
                            size: 18,
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF6B7280),
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? '',
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
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
