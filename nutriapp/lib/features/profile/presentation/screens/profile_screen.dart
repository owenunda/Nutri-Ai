import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/profile_repository.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.onLogout,
  });

  final String userName;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _profileRepository;
  late Future<UserProfile> _profileFuture;
  bool _mealRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _profileRepository = ProfileRepository();
    _profileFuture = _profileRepository.getProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _profileRepository.getProfile();
    });

    await _profileFuture;
  }

  Future<void> _openConfiguration(UserProfile profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );

    if (updated == true && mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProfileLoadingView();
        }

        if (snapshot.hasError) {
          return _ProfileErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshProfile,
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return _ProfileErrorView(
            message: 'No se pudo cargar tu perfil.',
            onRetry: _refreshProfile,
          );
        }

        return RefreshIndicator(
          color: _ProfileColors.green,
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProfileTopBar(),
                const SizedBox(height: 52),
                Text(
                  profile.name.isEmpty ? widget.userName : profile.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', 
                    color: _ProfileColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.membershipText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', 
                    color: _ProfileColors.text.withValues(alpha: 0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStatCard(
                        value: profile.age?.toString() ?? '--',
                        unit: '',
                        label: 'EDAD',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileStatCard(
                        value: _formatProfileNumber(profile.weight),
                        unit: 'kg',
                        label: 'PESO',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileStatCard(
                        value: _formatHeight(profile.height),
                        unit: 'cm',
                        label: 'ALTURA',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 42),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Objetivo nutricional',
                        style: TextStyle(fontFamily: 'PlusJakartaSans', 
                          color: _ProfileColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ACTIVO',
                        style: TextStyle(fontFamily: 'Inter', 
                          color: _ProfileColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _NutritionGoalSelector(goal: profile.goal),
                const SizedBox(height: 42),
                Text(
                  'Ajustes y recordatorios',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', 
                    color: _ProfileColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsCard(
                  mealRemindersEnabled: _mealRemindersEnabled,
                  onMealReminderChanged: (value) {
                    setState(() {
                      _mealRemindersEnabled = value;
                    });
                  },
                  onOpenConfiguration: () => _openConfiguration(profile),
                ),
                const SizedBox(height: 44),
                _LogoutButton(onPressed: widget.onLogout),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _ProfileColors.green),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB42318),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  color: _ProfileColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', 
                  color: _ProfileColors.muted.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                textButton: 'Intentar de nuevo',
                icon: Icons.refresh_rounded,
                height: 48,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _ProfileColors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _ProfileColors.green.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEFF3F5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'NutriAI',
          style: TextStyle(fontFamily: 'PlusJakartaSans', 
            color: _ProfileColors.green,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.notifications_rounded,
          color: Color(0xFF94A3B8),
          size: 27,
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', 
                    color: _ProfileColors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(fontFamily: 'Inter', 
                        color: _ProfileColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              color: const Color(0xFFABB0B6),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionGoalSelector extends StatelessWidget {
  const _NutritionGoalSelector({required this.goal});

  final String? goal;

  @override
  Widget build(BuildContext context) {
    final activeGoal = _normalizeGoal(goal);
    final goals = [
      _GoalOption(
        label: 'Bajar peso',
        value: 'lose',
        icon: Icons.trending_down_rounded,
      ),
      _GoalOption(
        label: 'Mantener',
        value: 'maintain',
        icon: Icons.balance_rounded,
      ),
      _GoalOption(
        label: 'Subir masa',
        value: 'gain',
        icon: Icons.fitness_center_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(38),
      ),
      child: Row(
        children: [
          for (final item in goals)
            Expanded(
              child: _GoalPill(
                option: item,
                isActive: item.value == activeGoal,
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({
    required this.option,
    required this.isActive,
  });

  final _GoalOption option;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 136,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            option.icon,
            color: isActive ? _ProfileColors.green : _ProfileColors.muted,
            size: 25,
          ),
          const SizedBox(height: 16),
          Text(
            option.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', 
              color: isActive ? _ProfileColors.green : _ProfileColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.mealRemindersEnabled,
    required this.onMealReminderChanged,
    required this.onOpenConfiguration,
  });

  final bool mealRemindersEnabled;
  final ValueChanged<bool> onMealReminderChanged;
  final VoidCallback onOpenConfiguration;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.access_time_filled_rounded,
            iconColor: const Color(0xFF066D82),
            iconBackground: const Color(0xFFA8F1F6),
            title: 'Recordatorios de comida',
            subtitle: 'Alertas diarias para 4 comidas',
            trailing: Switch(
              value: mealRemindersEnabled,
              activeThumbColor: _ProfileColors.green,
              activeTrackColor: const Color(0xFF69E7A4),
              onChanged: onMealReminderChanged,
            ),
          ),
          const _SettingsRow(
            icon: Icons.notifications_active_rounded,
            iconColor: Color(0xFF1D4ED8),
            iconBackground: Color(0xFFE7EAFF),
            title: 'Configuración de notificaciones',
            subtitle: 'Push, correo y SMS',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
          ),
          _SettingsRow(
            icon: Icons.tune_rounded,
            iconColor: _ProfileColors.green,
            iconBackground: const Color(0xFFE7F7EF),
            title: 'Configuración',
            subtitle: 'Edad, altura, sexo, objetivo y correo',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFADB4BC),
              size: 30,
            ),
            onTap: onOpenConfiguration,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        color: _ProfileColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(fontFamily: 'Inter', 
                        color: _ProfileColors.text.withValues(alpha: 0.72),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 24),
        label: Text(
          'Cerrar sesión',
          style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileColors.muted,
          side: BorderSide(
            color: AppTheme.onSurface.withValues(alpha: 0.15),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ProfileColors {
  const _ProfileColors._();

  static const Color green = AppTheme.primaryStart;
  static const Color text = AppTheme.onSurface;
  static const Color muted = AppTheme.onSurfaceVariant;
}

String _formatProfileNumber(double? value) {
  if (value == null) {
    return '--';
  }

  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _formatHeight(double? value) {
  if (value == null) {
    return '--';
  }

  final height = value <= 3 ? value * 100 : value;
  return _formatProfileNumber(height);
}

String _normalizeGoal(String? goal) {
  final value = goal?.toLowerCase().trim() ?? '';

  if (value.contains('bajar') ||
      value.contains('perder') ||
      value.contains('lose')) {
    return 'lose';
  }

  if (value.contains('subir') ||
      value.contains('ganar') ||
      value.contains('gain') ||
      value.contains('masa')) {
    return 'gain';
  }

  return 'maintain';
}
