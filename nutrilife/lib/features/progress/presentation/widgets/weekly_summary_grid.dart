import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';
import 'week_calories_card.dart' show formatKcal;

class WeeklySummaryGrid extends StatelessWidget {
  final WeekStats week;

  const WeeklySummaryGrid({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final limit = week.dailyLimit;
    final tiles = [
      ('PROMEDIO DIARIO', '${formatKcal(week.average)} kcal'),
      ('META DIARIA', limit == null ? '--' : '${formatKcal(limit)} kcal'),
      ('DÍAS EN META', limit == null ? '--' : '${week.daysOnTarget} de 7'),
      ('TOTAL SEMANA', '${formatKcal(week.total)} kcal'),
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
