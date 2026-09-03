import 'package:flutter/material.dart';

import '../../data/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _sexController;
  late final TextEditingController _goalController;
  late final String _initialWeightText;

  final List<String> _ageOptions = List.generate(85, (index) => '${index + 16}');
  final List<String> _heightOptions = List.generate(
    101,
    (index) => (1.50 + (index / 100)).toStringAsFixed(2),
  );
  final List<String> _weightOptions = List.generate(
    441,
    (index) => (30 + (index * 0.5)).toStringAsFixed(1),
  );
  final List<String> _sexOptions = const ['Hombre', 'Mujer'];
  final List<String> _goalOptions = const [
    'Bajar de peso',
    'Mantener peso',
    'Subir de peso',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '18',
    );
    _heightController = TextEditingController(
      text: _initialHeight(widget.profile.height),
    );
    _initialWeightText = _initialWeight(widget.profile.weight);
    _weightController = TextEditingController(text: _initialWeightText);
    _sexController = TextEditingController(
      text: widget.profile.sex?.isNotEmpty == true ? widget.profile.sex! : 'Hombre',
    );
    _goalController = TextEditingController(
      text: _goalLabel(widget.profile.goal),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sexController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final age = int.tryParse(_ageController.text);
    final heightInMeters = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final sex = _sexController.text.trim();
    final goal = _goalController.text.trim();

    if (age == null ||
        heightInMeters == null ||
        weight == null ||
        sex.isEmpty ||
        goal.isEmpty) {
      _showSnackBar('Selecciona todos los datos para continuar.');
      return;
    }

    if (heightInMeters < 1.50 || heightInMeters > 2.50) {
      _showSnackBar('Selecciona una altura válida entre 1.50 cm y 2.50 cm.');
      return;
    }

    final weightChanged = _weightController.text != _initialWeightText;
    if (weightChanged) {
      final confirmed = await _confirmWeightChange();
      if (!confirmed) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileRepository.updateProfile(
        age: age,
        height: heightInMeters * 100,
        weight: weight,
        goal: _backendGoal(goal),
        sex: sex,
        email: widget.profile.email,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ProfileException catch (error) {
      if (mounted) {
        _showSnackBar(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo actualizar tu perfil. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _confirmWeightChange() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: _editProfileShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB45309),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vas a actualizar tu peso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _EditProfileColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Este cambio puede afectar tus ajustes actuales, como tu meta calórica diaria y tu plan nutricional. NutriLife recalculará tus objetivos con el nuevo valor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _EditProfileColors.muted.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _EditProfileColors.muted,
                          side: BorderSide(
                            color: _EditProfileColors.text.withValues(alpha: 0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _EditProfileColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: _editProfileShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFB42318).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB42318),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: _EditProfileColors.text,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
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
      backgroundColor: const Color(0xFFF5F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _EditProfileColors.green,
                    iconSize: 30,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Configuración',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _EditProfileColors.green,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Datos nutricionales',
                style: TextStyle(
                  color: _EditProfileColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Actualiza tus datos para que NutriLife ajuste mejor tu plan.',
                style: TextStyle(
                  color: _EditProfileColors.muted.withValues(alpha: 0.86),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              _ConfigCard(
                children: [
                  _PickerRow(
                    label: 'Edad',
                    controller: _ageController,
                    options: _ageOptions,
                    unit: 'años',
                    icon: Icons.calendar_month_outlined,
                  ),
                  const _ConfigDivider(),
                  _PickerRow(
                    label: 'Altura',
                    controller: _heightController,
                    options: _heightOptions,
                    unit: 'cm',
                    icon: Icons.height_rounded,
                  ),
                  const _ConfigDivider(),
                  _PickerRow(
                    label: 'Peso',
                    controller: _weightController,
                    options: _weightOptions,
                    unit: 'kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const _ConfigDivider(),
                  _PickerRow(
                    label: 'Sexo',
                    controller: _sexController,
                    options: _sexOptions,
                    icon: Icons.person_outline_rounded,
                  ),
                  const _ConfigDivider(),
                  _PickerRow(
                    label: 'Objetivo',
                    controller: _goalController,
                    options: _goalOptions,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Cuenta',
                style: TextStyle(
                  color: _EditProfileColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              _ConfigCard(
                children: [
                  _StaticInfoRow(
                    label: 'Email',
                    value: widget.profile.email.isEmpty
                        ? 'Correo no disponible'
                        : widget.profile.email,
                    icon: Icons.email_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              SizedBox(
                height: 60,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: _EditProfileColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _EditProfileColors.green.withValues(alpha: 0.52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 8,
                    shadowColor: _EditProfileColors.green.withValues(alpha: 0.22),
                  ),
                  icon: Icon(
                    _isSaving
                        ? Icons.hourglass_top_rounded
                        : Icons.check_rounded,
                    size: 22,
                  ),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: _editProfileShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _PickerRow extends StatefulWidget {
  const _PickerRow({
    required this.label,
    required this.controller,
    required this.options,
    required this.icon,
    this.unit,
  });

  final String label;
  final TextEditingController controller;
  final List<String> options;
  final IconData icon;
  final String? unit;

  @override
  State<_PickerRow> createState() => _PickerRowState();
}

class _PickerRowState extends State<_PickerRow> {
  Future<void> _openPicker() async {
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 380),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView.separated(
            itemCount: widget.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final option = widget.options[index];
              final selected = option == widget.controller.text;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(option),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? _EditProfileColors.green.withValues(alpha: 0.10)
                          : const Color(0xFFF0F3F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 32),
                        Expanded(
                          child: Text(
                            _valueWithUnit(option),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _EditProfileColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: _EditProfileColors.green,
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

    setState(() {
      widget.controller.text = selectedValue;
    });
  }

  String _valueWithUnit(String value) {
    final unit = widget.unit;
    if (unit == null || unit.isEmpty) {
      return value;
    }

    return '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: _EditProfileColors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: _EditProfileColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _valueWithUnit(widget.controller.text),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _EditProfileColors.text.withValues(alpha: 0.72),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFADB4BC),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticInfoRow extends StatelessWidget {
  const _StaticInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE7EAFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1D4ED8),
              size: 24,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _EditProfileColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _EditProfileColors.text.withValues(alpha: 0.70),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigDivider extends StatelessWidget {
  const _ConfigDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xFFE9EEF2),
      indent: 94,
    );
  }
}

class _EditProfileColors {
  const _EditProfileColors._();

  static const Color green = Color(0xFF0A6B3F);
  static const Color text = Color(0xFF20252B);
  static const Color muted = Color(0xFF5B626B);
}

String _initialHeight(double? height) {
  if (height == null) {
    return '1.70';
  }

  final value = height <= 3 ? height : height / 100;
  final safeValue = value.clamp(1.50, 2.50);
  return safeValue.toStringAsFixed(2);
}

String _initialWeight(double? weight) {
  if (weight == null) {
    return '70.0';
  }

  final safeValue = weight.clamp(30.0, 250.0);
  final rounded = (safeValue * 2).round() / 2;
  return rounded.toStringAsFixed(1);
}

String _goalLabel(String? goal) {
  final normalized = goal?.toLowerCase() ?? '';

  if (normalized.contains('perder') ||
      normalized.contains('bajar') ||
      normalized.contains('lose')) {
    return 'Bajar de peso';
  }

  if (normalized.contains('ganar') ||
      normalized.contains('subir') ||
      normalized.contains('gain')) {
    return 'Subir de peso';
  }

  return 'Mantener peso';
}

String _backendGoal(String goal) {
  switch (goal) {
    case 'Bajar de peso':
      return 'Perder peso';
    case 'Subir de peso':
      return 'Ganar peso';
    default:
      return 'Mantener peso';
  }
}

List<BoxShadow> get _editProfileShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];
}
