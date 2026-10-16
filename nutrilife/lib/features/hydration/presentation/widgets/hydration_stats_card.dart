import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/water_streak_repository.dart';

class HydrationStatsCard extends StatefulWidget {
  const HydrationStatsCard({
    super.key,
    required this.accountId,
    this.title,
    this.showStreakSummary = true,
    this.showMascot = true,
  });

  final String accountId;
  /// Sin título usa "Tu hidratación" en el idioma activo.
  final String? title;
  final bool showStreakSummary;
  final bool showMascot;

  @override
  State<HydrationStatsCard> createState() => _HydrationStatsCardState();
}

class _HydrationStatsCardState extends State<HydrationStatsCard>
    with WidgetsBindingObserver {
  late WaterStreakRepository _repository = WaterStreakRepository(
    accountId: widget.accountId,
  );
  late Future<WaterStreakSnapshot> _snapshot = _repository.load();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WaterStreakState.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WaterStreakState.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HydrationStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _repository = WaterStreakRepository(accountId: widget.accountId);
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _snapshot = _repository.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WaterStreakSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF1683A0)),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ErrorCard(onRetry: _refresh);
        }
        return _HydrationStatsContent(
          title: widget.title ?? context.l10n.hydrationStatsTitle,
          snapshot: snapshot.data!,
          showStreakSummary: widget.showStreakSummary,
          showMascot: widget.showMascot,
        );
      },
    );
  }
}

class _HydrationStatsContent extends StatelessWidget {
  const _HydrationStatsContent({
    required this.title,
    required this.snapshot,
    required this.showStreakSummary,
    required this.showMascot,
  });

  final String title;
  final WaterStreakSnapshot snapshot;
  final bool showStreakSummary;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateTime.parse(snapshot.date);
    final weekdayLabels = l10n.hydrationWeekdayInitials.split(',');
    final labels = List<String>.generate(7, (index) {
      final date = DateTime(today.year, today.month, today.day - (6 - index));
      return weekdayLabels[date.weekday - 1];
    }, growable: false);

    return Container(
      key: const ValueKey('hydration-stats-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EEF1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164A5A).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1683A0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      showStreakSummary
                          ? l10n.hydrationEveryGlassCounts
                          : l10n.hydrationGlassesLogged,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (showMascot)
                Image.asset(
                  'assets/images/nutria_estadisticas_cientifica_borde_negro_1024.png',
                  width: 62,
                  height: 66,
                  fit: BoxFit.contain,
                  semanticLabel: l10n.hydrationScientistOtter,
                ),
            ],
          ),
          if (showStreakSummary) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: '${snapshot.currentStreak}',
                    label: l10n.hydrationStatCurrentStreak,
                    color: const Color(0xFFE89B27),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    icon: Icons.emoji_events_rounded,
                    value: '${snapshot.bestStreak}',
                    label: l10n.hydrationStatBestStreak,
                    color: const Color(0xFF6681C8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    icon: Icons.water_drop_rounded,
                    value: '${snapshot.totalGlasses}',
                    label: l10n.hydrationStatTotalGlasses,
                    color: const Color(0xFF2997B3),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.hydrationLast7Days,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.hydrationGoalsMet(
                  snapshot.lastSevenDays
                      .where((value) => value >= WaterStreakRepository.dailyGoal)
                      .length,
                ),
                style: const TextStyle(
                  color: Color(0xFF6C858D),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (
                var index = 0;
                index < snapshot.lastSevenDays.length;
                index++
              )
                Expanded(
                  child: _WaterDayBar(
                    label: labels[index],
                    glasses: snapshot.lastSevenDays[index],
                    isToday: index == 6,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.hydrationDisclaimer(WaterStreakRepository.dailyGoal),
            style: const TextStyle(
              color: Color(0xFF83949A),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF758890),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterDayBar extends StatelessWidget {
  const _WaterDayBar({
    required this.label,
    required this.glasses,
    required this.isToday,
  });

  final String label;
  final int glasses;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final completed = glasses >= WaterStreakRepository.dailyGoal;
    final fraction = glasses / WaterStreakRepository.dailyGoal;
    return Column(
      children: [
        Text(
          '$glasses',
          style: TextStyle(
            color: completed
                ? const Color(0xFF1683A0)
                : const Color(0xFF82949A),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 62,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 18,
              height: 12 + (fraction.clamp(0, 1) * 42),
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF1683A0)
                    : const Color(0xFF8DD5E3),
                borderRadius: BorderRadius.circular(99),
                border: isToday
                    ? Border.all(color: const Color(0xFF14677A), width: 1.5)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isToday ? const Color(0xFF1683A0) : const Color(0xFF84949A),
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.hydrationStatsLoadError,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: context.l10n.commonRetry,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1683A0)),
          ),
        ],
      ),
    );
  }
}
