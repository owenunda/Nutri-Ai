import 'package:flutter/material.dart';

import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../premium/presentation/widgets/premium_promo_card.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../hydration/presentation/widgets/hydration_stats_card.dart';
import '../../data/progress_repository.dart';
import '../widgets/register_weight_sheet.dart';
import '../widgets/week_calories_card.dart';
import '../widgets/weekly_summary_grid.dart';
import '../widgets/weight_sparkline.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.user,
    this.refreshToken = 0,
    this.repository,
  });

  final Map<String, dynamic>? user;
  final int refreshToken;
  @visibleForTesting
  final ProgressRepository? repository;

  static const Color _text = AppTheme.onSurface;
  static const Color _muted = AppTheme.onSurfaceVariant;
  static const Color _green = AppTheme.primaryStart;
  static const Color _mint = Color(0xFF69E7A4);
  static const Color _blue = AppTheme.tertiary;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressRepository _repository;
  late Future<ProgressData> _progressFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProgressRepository();
    _progressFuture = _repository.fetchProgress();
    MealLogState.instance.addListener(_onMealLogged);
  }

  @override
  void dispose() {
    MealLogState.instance.removeListener(_onMealLogged);
    super.dispose();
  }

  void _onMealLogged() {
    if (!mounted) return;
    setState(() {
      _progressFuture = _repository.fetchProgress();
    });
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _progressFuture = _repository.fetchProgress();
    }
  }

  Future<void> _refreshProgress() async {
    setState(() {
      _progressFuture = _repository.fetchProgress();
    });

    await _progressFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgressData>(
      future: _progressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProgressLoadingView();
        }

        if (snapshot.hasError) {
          return _ProgressErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshProgress,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return _ProgressErrorView(
            message: context.l10n.progressErrorLoadShort,
            onRetry: _refreshProgress,
          );
        }

        return RefreshIndicator(
          color: ProgressScreen._green,
          onRefresh: _refreshProgress,
          child: _ProgressContent(data: data, accountId: _accountId),
        );
      },
    );
  }

  String get _accountId {
    final email = widget.user?['email']?.toString().trim();
    final id = widget.user?['id']?.toString().trim();
    if (email != null && email.isNotEmpty) return email;
    if (id != null && id.isNotEmpty) return id;
    return 'default';
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.data, required this.accountId});

  final ProgressData data;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progressKicker,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: ProgressScreen._green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      l10n.progressGreeting(data.firstName),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: ProgressScreen._text,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _GoalPill(goal: data.goalLabel),
            ],
          ),
          const SizedBox(height: 18),
          _WeightInsightCard(data: data),
          const SizedBox(height: 18),
          _TodayCaloriesCard(data: data),
          const SizedBox(height: 22),
          const _ProgressSectionHeading(
            title: 'CALORÍAS',
            subtitle: 'Tu consumo frente a la meta diaria',
            icon: Icons.local_fire_department_rounded,
            color: Color(0xFFE89B27),
          ),
          const SizedBox(height: 10),
          if (data.week != null)
            WeekCaloriesCard(
              week: data.week!,
              onCompleteProfile: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      profile: UserProfile.fromJson(data.profile),
                    ),
                  ),
                );
                if (updated == true) MealLogState.instance.bump();
              },
            )
          else
            const _ProgressUnavailableCard(
              message: 'Aún no hay suficientes datos para mostrar la semana.',
            ),
          const SizedBox(height: 22),
          const _ProgressSectionHeading(
            title: 'HIDRATACIÓN',
            subtitle: 'Un hábito complementario, día a día',
            icon: Icons.water_drop_rounded,
            color: Color(0xFF2997B3),
          ),
          const SizedBox(height: 10),
          HydrationStatsCard(
            accountId: accountId,
            title: 'Vasos de agua · últimos 7 días',
            showStreakSummary: false,
            showMascot: true,
          ),
          const SizedBox(height: 22),
          _WeightHistoryCard(
            records: data.orderedHistory,
            currentWeight: data.currentWeight,
          ),
          const SizedBox(height: 28),
          Text(
            data.week != null ? l10n.progressSummaryWeek : l10n.progressSummaryNutrition,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: ProgressScreen._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          data.week == null
              ? _NutritionAveragesGrid(data: data)
              : WeeklySummaryGrid(week: data.week!),
          const SizedBox(height: 24),
          const PremiumPromoCard(),
        ],
      ),
    );
  }
}

class _ProgressSectionHeading extends StatelessWidget {
 const _ProgressSectionHeading({
   required this.title,
   required this.subtitle,
   required this.icon,
   required this.color,
 });

 final String title;
 final String subtitle;
 final IconData icon;
 final Color color;

 @override
 Widget build(BuildContext context) {
   return Row(
     children: [
       Container(
         width: 34,
         height: 34,
         decoration: BoxDecoration(
           color: color.withValues(alpha: 0.1),
           borderRadius: BorderRadius.circular(11),
         ),
         child: Icon(icon, size: 18, color: color),
       ),
       const SizedBox(width: 10),
       Expanded(
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               title,
               style: TextStyle(
                 color: color,
                 fontSize: 10,
                 fontWeight: FontWeight.w900,
                 letterSpacing: 1.1,
               ),
             ),
             const SizedBox(height: 2),
             Text(
               subtitle,
               style: const TextStyle(
                 color: AppTheme.onSurfaceVariant,
                 fontSize: 11,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
         ),
       ),
     ],
   );
 }
}

class _ProgressUnavailableCard extends StatelessWidget {
 const _ProgressUnavailableCard({required this.message});

 final String message;

 @override
 Widget build(BuildContext context) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: Colors.white,
       borderRadius: BorderRadius.circular(18),
     ),
     child: Text(
       message,
       style: const TextStyle(
         color: AppTheme.onSurfaceVariant,
         fontSize: 12,
       ),
     ),
   );
 }
}

class _ProgressLoadingView extends StatelessWidget {
  const _ProgressLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        children: [
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(color: ProgressScreen._green),
          ),
        ],
      ),
    );
  }
}

class _ProgressErrorView extends StatelessWidget {
  const _ProgressErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _ProgressCard(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB42318).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB42318),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.progressErrorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  textButton: l10n.progressRetry,
                  icon: Icons.refresh_rounded,
                  height: 48,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: ProgressScreen._mint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        context.l10n.progressGoalPill(goal),
        style: TextStyle(
          fontFamily: 'Inter',
          color: const Color(0xFF064D31),
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeightInsightCard extends StatelessWidget {
  const _WeightInsightCard({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = data.latestWeightChange;
    final hasChange = change != null;
    final currentWeight = data.currentWeight;
    final isDown = hasChange && change < 0;
    final isUp = hasChange && change > 0;
    final icon = isDown
        ? Icons.trending_down_rounded
        : isUp
        ? Icons.trending_up_rounded
        : Icons.trending_flat_rounded;
    final highlightedText = hasChange
        ? '${change.abs().toStringAsFixed(1)}kg'
        : '';
    final mainText = _weightInsightText(change, l10n);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 164),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -14,
            child: SizedBox(
              width: 120,
              height: 90,
              child: WeightSparkline(
                weights: data.orderedHistory
                    .map((r) => r.weight)
                    .whereType<double>()
                    .toList()
                    .reversed
                    .take(7)
                    .toList()
                    .reversed
                    .toList(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: ProgressScreen._green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.progressWeightSummaryTitle,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: ProgressScreen._green,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (hasChange)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: mainText.$1),
                      TextSpan(
                        text: highlightedText,
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                      TextSpan(text: mainText.$2),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.progressCurrentWeight}\n'),
                      TextSpan(
                        text: currentWeight == null
                            ? l10n.progressNoRecord
                            : '${_formatDouble(currentWeight)}kg',
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                hasChange
                    ? l10n.progressCompareHint
                    : l10n.progressAddAnotherHint,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: ProgressScreen._muted.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showRegisterWeightSheet(
                  context,
                  lastWeight: data.currentWeight,
                  height: data.currentHeight,
                ),
                icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                label: Text(l10n.progressRegisterWeight),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ProgressScreen._green,
                  side: const BorderSide(color: Color(0xFFD1E7DA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Texto antes y después del número resaltado. La frase completa se traduce
  /// con una marca en el lugar del número, así cada idioma ordena como quiera.
  (String, String) _weightInsightText(double? change, AppLocalizations l10n) {
    if (change == null) {
      return ('', '');
    }

    const marker = '\u0001';
    final sentence = change < 0
        ? l10n.progressWeightDown(marker)
        : change > 0
        ? l10n.progressWeightUp(marker)
        : l10n.progressWeightChanged(marker);
    final parts = sentence.split(marker);
    return (parts.first, parts.last);
  }
}

class _TodayCaloriesCard extends StatelessWidget {
  const _TodayCaloriesCard({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dailyLimit = data.dailyLimit;
    final remaining = data.remaining;

    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressTodayCaloriesTitle,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(status: data.statusLabel, isExceeded: data.isExceeded),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKcal(data.totalConsumed, l10n),
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: ProgressScreen._green,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  dailyLimit == null
                      ? l10n.progressKcalConsumed
                      : l10n.progressKcalOfLimit(formatKcal(dailyLimit, l10n)),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.calorieProgress,
              minHeight: 12,
              backgroundColor: const Color(0xFFDDE4E8),
              valueColor: AlwaysStoppedAnimation<Color>(
                data.isExceeded
                    ? const Color(0xFFB42318)
                    : ProgressScreen._green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dailyLimit == null || remaining == null
                ? l10n.progressCompleteDataHint
                : l10n.progressGoalAndRemaining(
                    formatKcal(dailyLimit, l10n),
                    formatKcal(remaining, l10n),
                  ),
            style: TextStyle(
              fontFamily: 'Inter',
              color: ProgressScreen._muted.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isExceeded});

  final String status;
  final bool isExceeded;

  @override
  Widget build(BuildContext context) {
    final color = isExceeded ? const Color(0xFFB42318) : ProgressScreen._green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({
    required this.records,
    required this.currentWeight,
  });

  final List<PhysicalRecord> records;
  final double? currentWeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validRecords = records
        .where((record) => record.weight != null)
        .toList();

    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressHistoryTitle,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: ProgressScreen._blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentWeight == null
                    ? l10n.progressHistoryNoCurrent
                    : l10n.progressHistoryCurrent(_formatDouble(currentWeight!)),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: ProgressScreen._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: validRecords.isEmpty
                ? const _EmptyHistoryState()
                : CustomPaint(
                    painter: _WeightHistoryPainter(records: validRecords),
                  ),
          ),
          if (validRecords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _historyLabels(
                validRecords,
                l10n,
              ).map((label) => _AxisLabel(label)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.progressHistoryEmpty,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          color: ProgressScreen._muted.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NutritionAveragesGrid extends StatelessWidget {
  const _NutritionAveragesGrid({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dailyLimit = data.dailyLimit;
    final remaining = data.remaining;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AverageTile(
                label: l10n.progressTileConsumed,
                value: '${formatKcal(data.totalConsumed, l10n)} kcal',
                detail: l10n.progressTileLoggedToday,
                accent: ProgressScreen._green,
                progress: data.calorieProgress,
                highlighted: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AverageTile(
                label: l10n.progressTileDailyGoal,
                value: dailyLimit == null
                    ? '--'
                    : '${formatKcal(dailyLimit, l10n)} kcal',
                accent: ProgressScreen._green,
                progress: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AverageTile(
                label: l10n.progressTileRemaining,
                value: remaining == null
                    ? '--'
                    : '${formatKcal(remaining, l10n)} kcal',
                accent: const Color(0xFF0F7C86),
                progress: 1 - data.calorieProgress,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AverageTile(
                label: l10n.progressTileStatus,
                value: data.statusLabel,
                accent: data.isExceeded
                    ? const Color(0xFFB42318)
                    : ProgressScreen._blue,
                progress: data.isExceeded
                    ? 1
                    : data.calorieProgress,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AverageTile extends StatelessWidget {
  const _AverageTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.progress,
    this.detail,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String? detail;
  final Color accent;
  final double progress;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Stack(
        children: [
          if (highlighted)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: ProgressScreen._green,
                child: SizedBox(width: 3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ProgressScreen._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: ProgressScreen._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: ProgressScreen._green,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1).toDouble(),
                      minHeight: 4,
                      backgroundColor: const Color(0xFFD6DEE3),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: child,
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        color: const Color(0xFF9AA4AF),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _WeightHistoryPainter extends CustomPainter {
  const _WeightHistoryPainter({required this.records});

  final List<PhysicalRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final weights = records.map((record) => record.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight == 0 ? 1 : maxWeight - minWeight;
    final points = <Offset>[];

    for (var index = 0; index < weights.length; index++) {
      final x = weights.length == 1
          ? size.width * 0.5
          : size.width * (index / (weights.length - 1));
      final normalized = (weights[index] - minWeight) / range;
      final y = size.height * 0.78 - (normalized * size.height * 0.58);
      points.add(Offset(x, y));
    }

    final paint = Paint()
      ..color = ProgressScreen._blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    final dotFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..color = ProgressScreen._blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotFill);
      canvas.drawCircle(point, 4, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightHistoryPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}

List<String> _historyLabels(List<PhysicalRecord> records, AppLocalizations l10n) {
  final recordsWithDate = records
      .where((record) => record.recordDate != null)
      .toList();
  if (recordsWithDate.isEmpty) {
    return [l10n.progressAxisStart, l10n.progressAxisToday];
  }

  if (recordsWithDate.length <= 5) {
    return recordsWithDate
        .map((record) => _formatDate(record.recordDate!, l10n))
        .toList();
  }

  final indexes = <int>{
    0,
    (recordsWithDate.length * 0.25).round(),
    (recordsWithDate.length * 0.50).round(),
    (recordsWithDate.length * 0.75).round(),
    recordsWithDate.length - 1,
  }.toList()..sort();

  return indexes
      .map(
        (index) =>
            recordsWithDate[index.clamp(0, recordsWithDate.length - 1).toInt()],
      )
      .map((record) => _formatDate(record.recordDate!, l10n))
      .toList();
}

/// "ENE 5" / "JAN 5": mes abreviado en mayúsculas y día.
String _formatDate(DateTime date, AppLocalizations l10n) {
  return '${shortMonth(date, l10n.localeName).toUpperCase()} ${date.day}';
}

String _formatDouble(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}
