import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../hydration/data/water_streak_repository.dart';
import '../../../progress/data/progress_repository.dart';

class ProfileStreaksCard extends StatefulWidget {
  const ProfileStreaksCard({super.key, required this.accountId});

  final String accountId;

  @override
  State<ProfileStreaksCard> createState() => _ProfileStreaksCardState();
}

class _ProfileStreaksCardState extends State<ProfileStreaksCard>
    with WidgetsBindingObserver {
  late WaterStreakRepository _waterRepository;
  final _progressRepository = ProgressRepository();
  late Future<_ProfileStreaks> _streaks;

  @override
  void initState() {
    super.initState();
    _waterRepository = WaterStreakRepository(accountId: widget.accountId);
    _streaks = _loadStreaks();
    WidgetsBinding.instance.addObserver(this);
    WaterStreakState.instance.addListener(_refresh);
    MealLogState.instance.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ProfileStreaksCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _waterRepository = WaterStreakRepository(accountId: widget.accountId);
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WaterStreakState.instance.removeListener(_refresh);
    MealLogState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _streaks = _loadStreaks();
    });
  }

  Future<_ProfileStreaks> _loadStreaks() async {
    final waterFuture = _waterRepository.load();
    late ProgressData progress;
    try {
      progress = await _progressRepository.fetchProgress();
    } on ProgressException catch (error) {
      final water = await waterFuture;
      return _ProfileStreaks(
        waterCurrent: water.currentStreak,
        waterBest: water.bestStreak,
        caloriesCurrent: null,
        caloriesBest: null,
        calorieGoalAvailable: false,
        calorieErrorMessage: error.message,
      );
    }
    final water = await waterFuture;
    final week = progress.week;
    return _ProfileStreaks(
      waterCurrent: water.currentStreak,
      waterBest: water.bestStreak,
      caloriesCurrent: week?.hasTargetHistory == true
          ? week!.currentGoalStreak()
          : null,
      caloriesBest: week?.hasTargetHistory == true
          ? week!.bestGoalStreak()
          : null,
      calorieGoalAvailable: week?.hasTargetHistory ?? false,
      calorieErrorMessage: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileStreaks>(
      future: _streaks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1683A0)),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _StreaksErrorCard(onRetry: _refresh);
        }

        final streaks = snapshot.data!;
        final l10n = context.l10n;
        return Container(
          key: const ValueKey('profile-streaks-card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5ECEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileStreaksTitle,
                style: const TextStyle(
                  color: AppTheme.primaryStart,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StreakMetric(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFE89B27),
                      title: l10n.profileStreaksCalorieGoal,
                      current: streaks.caloriesCurrent,
                      best: streaks.caloriesBest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StreakMetric(
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2997B3),
                      title: l10n.profileStreaksHydration,
                      current: streaks.waterCurrent,
                      best: streaks.waterBest,
                    ),
                  ),
                ],
              ),
              if (streaks.calorieErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.profileStreaksCalorieError(streaks.calorieErrorMessage!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ] else if (!streaks.calorieGoalAvailable) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.profileStreaksNoWeekData,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  l10n.profileStreaksCalorieNote,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStreaks {
  const _ProfileStreaks({
    required this.waterCurrent,
    required this.waterBest,
    required this.caloriesCurrent,
    required this.caloriesBest,
    required this.calorieGoalAvailable,
    required this.calorieErrorMessage,
  });

  final int waterCurrent;
  final int waterBest;
  final int? caloriesCurrent;
  final int? caloriesBest;
  final bool calorieGoalAvailable;
  final String? calorieErrorMessage;
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.icon,
    required this.color,
    required this.title,
    required this.current,
    required this.best,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int? current;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final currentValue = current != null && current! >= 7
        ? '7+'
        : current?.toString() ?? '--';
    final bestValue = best != null && best! >= 7
        ? '7+'
        : best?.toString() ?? '--';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileStreaksDays(currentValue),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            context.l10n.profileStreaksCurrentBest(bestValue),
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreaksErrorCard extends StatelessWidget {
  const _StreaksErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.profileStreaksLoadError,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
