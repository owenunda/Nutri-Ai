import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';
import 'week_calories_card.dart' show formatKcal;

class WeeklySummaryGrid extends StatelessWidget {
  final WeekStats week;

  const WeeklySummaryGrid({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final limit = week.dailyLimit;
    final tiles = [
      (l10n.progressTileDailyAverage, '${formatKcal(week.average, l10n)} kcal'),
      (l10n.progressTileDailyGoal, limit == null ? '--' : '${formatKcal(limit, l10n)} kcal'),
      (l10n.progressTileDaysOnTarget, limit == null ? '--' : l10n.progressDaysOfSeven(week.daysOnTarget)),
      (l10n.progressTileWeekTotal, '${formatKcal(week.total, l10n)} kcal'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: [
        for (final (label, value) in tiles)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
              ],
            ),
          ),
      ],
    );
  }
}
