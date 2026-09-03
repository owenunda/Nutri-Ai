import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../data/setup_repository.dart';

class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({
    super.key,
    this.userName,
    this.age,
    this.weight,
    this.height,
  });

  final String? userName;
  final int? age;
  final double? weight;
  final double? height;

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  static const double _activityFactor = 1.2;
  static const double _maxWeightLossDeficit = 500;
  static const double _weightLossDeficitRatio = 0.15;
  static const double _minWeightLossCalories = 1200;
  static const int _minSafeDailyCalories = 1200;

  final SetupRepository _setupRepository = SetupRepository();
  _GoalType _selectedGoal = _GoalType.maintainWeight;
  bool _isSaving = false;

  double get _progress => 1.0;

  int get _recommendedCalories {
    final age = widget.age;
    final weight = widget.weight;
    final height = widget.height;

    if (age == null || weight == null || height == null) {
      return _selectedGoal.info.calories;
    }

    final bmr = (10 * weight) + (6.25 * height) - (5 * age) - 80;
    final maintenanceCalories = bmr * _activityFactor;
    final adjustedCalories = switch (_selectedGoal) {
      _GoalType.loseWeight => _weightLossCalories(maintenanceCalories),
      _GoalType.maintainWeight => maintenanceCalories,
      _GoalType.gainWeight =>
        maintenanceCalories + _moderateAdjustment(maintenanceCalories),
    };

    return _safeDailyCalories(adjustedCalories);
  }

  double _weightLossCalories(double maintenanceCalories) {
    final deficit = _moderateAdjustment(maintenanceCalories);
    final calories = maintenanceCalories - deficit;
    return calories < _minWeightLossCalories ? _minWeightLossCalories : calories;
  }

  double _moderateAdjustment(double maintenanceCalories) {
    final proportionalDeficit = maintenanceCalories * _weightLossDeficitRatio;
    return proportionalDeficit > _maxWeightLossDeficit
        ? _maxWeightLossDeficit
        : proportionalDeficit;
  }

  int _safeDailyCalories(double calories) {
    final roundedCalories = calories.round();
    return roundedCalories < _minSafeDailyCalories
        ? _minSafeDailyCalories
        : roundedCalories.clamp(_minSafeDailyCalories, 10000).toInt();
  }

  Future<void> _goHome() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _setupRepository.updateProfile(
        goal: _selectedGoal.info.backendGoal,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(user: {'name': widget.userName ?? 'Usuario'}),
        ),
        (route) => false,
      );
    } on SetupException catch (error) {
      if (mounted) {
        _showSnackBar(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo guardar tu meta. Inténtalo de nuevo.');
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
              color: const Color(0xFFB42318).withValues(alpha: 0.16),
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
                  color: const Color(0xFFB42318).withValues(alpha: 0.12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo guardar',
                      style: TextStyle(
                        color: Color(0xFF2C2F31),
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
            top: -60,
            left: -50,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.12),
              size: 150,
            ),
          ),
          Positioned(
            top: 150,
            right: -40,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 110,
            ),
          ),
          Positioned(
            bottom: 180,
            left: 20,
            child: _GlowCircle(
              color: AppTheme.primaryStart.withValues(alpha: 0.08),
              size: 54,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.primaryStart,
                            ),
                            iconSize: 30,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 44,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'NutruLife',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.primaryStart,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Define tu objetivo',
                        style: TextStyle(
                          color: Color(0xFF2C2F31),
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Calcularemos tu plan según lo que\nquieras lograr.',
                        style: TextStyle(
                          color: const Color(
                            0xFF595C5E,
                          ).withValues(alpha: 0.92),
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _GoalOptionCard(
                        goalType: _GoalType.loseWeight,
                        selected: _selectedGoal == _GoalType.loseWeight,
                        onTap: () {
                          setState(() {
                            _selectedGoal = _GoalType.loseWeight;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _GoalOptionCard(
                        goalType: _GoalType.maintainWeight,
                        selected: _selectedGoal == _GoalType.maintainWeight,
                        onTap: () {
                          setState(() {
                            _selectedGoal = _GoalType.maintainWeight;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _GoalOptionCard(
                        goalType: _GoalType.gainWeight,
                        selected: _selectedGoal == _GoalType.gainWeight,
                        onTap: () {
                          setState(() {
                            _selectedGoal = _GoalType.gainWeight;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.primaryStart.withValues(
                              alpha: 0.16,
                            ),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1E2A24,
                              ).withValues(alpha: 0.05),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'CALORÍAS DIARIAS RECOMENDADAS',
                                style: TextStyle(
                                  color: const Color(
                                    0xFF595C5E,
                                  ).withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: _recommendedCalories.toDouble(),
                              ),
                              duration: const Duration(milliseconds: 250),
                              builder: (context, value, child) {
                                return RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: AppTheme.primaryStart,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: value.round().toString(),
                                        style: const TextStyle(
                                          fontSize: 56,
                                          letterSpacing: -1.6,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' kcal',
                                        style: TextStyle(
                                          fontSize: 26,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Basado en tu metabolismo basal y\nnivel de actividad actual.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(
                                  0xFF595C5E,
                                ).withValues(alpha: 0.95),
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCDCF6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1E2A24,
                                      ).withValues(alpha: 0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppTheme.primaryStart,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'PLAN PERSONALIZADO',
                                      style: TextStyle(
                                        color: Color(0xFF2C2F31),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6B61F4,
                                    ).withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF6B61F4),
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
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
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFDDE4E8),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryStart,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 26),
                      PrimaryButton(
                        textButton: _isSaving
                            ? 'Guardando meta...'
                            : 'Empieza tu meta',
                        width: double.infinity,
                        height: 58,
                        icon: _isSaving
                            ? Icons.hourglass_top_rounded
                            : Icons.arrow_forward_rounded,
                        iconSize: 22,
                        onPressed: _isSaving ? null : _goHome,
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

class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    required this.goalType,
    required this.selected,
    required this.onTap,
  });

  final _GoalType goalType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = goalType.info;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppTheme.primaryStart : Colors.transparent,
              width: selected ? 2.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF1E2A24,
                ).withValues(alpha: selected ? 0.07 : 0.04),
                blurRadius: selected ? 24 : 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: info.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.title,
                      style: const TextStyle(
                        color: Color(0xFF2C2F31),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.subtitle,
                      style: TextStyle(
                        color: const Color(0xFF595C5E).withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryStart,
                      width: 2.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primaryStart,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GoalType { loseWeight, maintainWeight, gainWeight }

extension _GoalTypeInfoX on _GoalType {
  _GoalTypeInfo get info {
    switch (this) {
      case _GoalType.loseWeight:
        return const _GoalTypeInfo(
          title: 'Bajar de peso',
          backendGoal: 'Perder peso',
          subtitle: 'Déficit calórico saludable',
          calories: 2100,
          icon: Icons.trending_down_rounded,
          iconColor: Color(0xFF14532D),
          iconBackground: Color(0xFF69E7A4),
        );
      case _GoalType.maintainWeight:
        return const _GoalTypeInfo(
          title: 'Mantener peso',
          backendGoal: 'Mantener peso',
          subtitle: 'Estabilidad y nutrición diaria',
          calories: 2450,
          icon: Icons.scale_rounded,
          iconColor: Color(0xFF1D4ED8),
          iconBackground: Color(0xFFCCD2FF),
        );
      case _GoalType.gainWeight:
        return const _GoalTypeInfo(
          title: 'Subir de peso',
          backendGoal: 'Ganar peso',
          subtitle: 'Superávit para masa muscular',
          calories: 2800,
          icon: Icons.trending_up_rounded,
          iconColor: Color(0xFF0E7490),
          iconBackground: Color(0xFF00D5FF),
        );
    }
  }
}

class _GoalTypeInfo {
  const _GoalTypeInfo({
    required this.title,
    required this.backendGoal,
    required this.subtitle,
    required this.calories,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String backendGoal;
  final String subtitle;
  final int calories;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
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
