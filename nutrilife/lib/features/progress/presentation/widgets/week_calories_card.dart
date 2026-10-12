import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';

String formatKcal(int value) => value
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

class WeekCaloriesCard extends StatefulWidget {
  final WeekStats week;
  final DateTime Function()? clock;
  final VoidCallback? onCompleteProfile;

  const WeekCaloriesCard({super.key, required this.week, this.clock, this.onCompleteProfile});

  @override
  State<WeekCaloriesCard> createState() => _WeekCaloriesCardState();
}

class _WeekCaloriesCardState extends State<WeekCaloriesCard> {
  static const _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _green = AppTheme.primaryStart;
  static const _amber = Color(0xFFF59E0B);

  DayCalories? _selected;

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final now = (widget.clock ?? DateTime.now)();
    final today = DateTime(now.year, now.month, now.day);
    final limit = week.dailyLimit;
    final maxValue = math.max(
      limit ?? 0,
      week.days.fold<int>(0, (m, d) => math.max(m, d.totalConsumed)),
    ).clamp(1, 1 << 31);

    final footer = limit == null
        ? 'Promedio: ${formatKcal(week.average)} kcal/día'
        : 'Promedio: ${formatKcal(week.average)} kcal/día · ${week.daysOnTarget} de 7 días en tu meta';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
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
              const Expanded(
                child: Text(
                  'Esta semana',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              if (_selected != null)
                Text(
                  '${_weekdays[_selected!.date.weekday - 1]} ${_selected!.date.day} · '
                  '${formatKcal(_selected!.totalConsumed)} kcal',
                  style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 18),
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
                                _initials[day.date.weekday - 1],
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
          const SizedBox(height: 14),
          Text(
            footer,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (limit == null)
            TextButton(
              onPressed: widget.onCompleteProfile,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Completa tu perfil'),
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
