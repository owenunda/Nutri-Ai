import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';

/// Miles separados: punto en español (1.850) y coma en inglés (1,850).
String formatKcal(int value, AppLocalizations l10n) {
  final separator = l10n.localeName == 'es' ? '.' : ',';
  return value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}$separator');
}

class WeekCaloriesCard extends StatefulWidget {
  final WeekStats week;
  final DateTime Function()? clock;
  final VoidCallback? onCompleteProfile;

  const WeekCaloriesCard({super.key, required this.week, this.clock, this.onCompleteProfile});

  @override
  State<WeekCaloriesCard> createState() => _WeekCaloriesCardState();
}

class _WeekCaloriesCardState extends State<WeekCaloriesCard> {
  static const _green = AppTheme.primaryStart;
  static const _amber = Color(0xFFF59E0B);

  DayCalories? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final week = widget.week;
    final now = (widget.clock ?? DateTime.now)();
    final today = DateTime(now.year, now.month, now.day);
    final limit = week.dailyLimit;
    final maxValue = math.max(
      limit ?? 0,
      week.days.fold<int>(0, (m, d) => math.max(m, d.totalConsumed)),
    ).clamp(1, 1 << 31);

    final footer = limit == null
        ? l10n.progressWeekAverage(formatKcal(week.average, l10n))
        : l10n.progressWeekAverageOnTarget(formatKcal(week.average, l10n), week.daysOnTarget);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progressWeekTitle,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (limit != null && _selected == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l10n.progressWeekOnTargetBadge(week.daysOnTarget),
                    style: const TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (_selected != null)
                Text(
                  l10n.progressWeekDaySelected(
                    shortWeekday(_selected!.date, l10n.localeName),
                    _selected!.date.day,
                    formatKcal(_selected!.totalConsumed, l10n),
                  ),
                  style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                if (limit != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20 + 110 * (limit / maxValue),
                    child: const _DashedLine(),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final day in week.days)
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey(
                            'week-bar-${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selected = day),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 18,
                                height: math.max(4, 110 * (day.totalConsumed / maxValue)),
                                decoration: BoxDecoration(
                                  color: limit != null && day.totalConsumed > limit
                                      ? _amber
                                      : (day.date == today ? _green : _green.withValues(alpha: 0.45)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                // Inicial del día: L M M J V S D / M T W T F S S.
                                shortWeekday(day.date, l10n.localeName)[0],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: day.date == today ? FontWeight.w900 : FontWeight.w600,
                                  color: day.date == today ? _green : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            footer,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (limit == null)
            TextButton(
              onPressed: widget.onCompleteProfile,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(l10n.progressCompleteProfile),
            ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          children: List.generate(
            count,
            (i) => Container(
              width: 4,
              height: 1.5,
              margin: const EdgeInsets.only(right: 4),
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}
