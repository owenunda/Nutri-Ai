import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../hydration/data/water_streak_repository.dart';
import '../../../hydration/presentation/widgets/water_progress_illustration.dart';

class WaterStreakHomeCard extends StatefulWidget {
  const WaterStreakHomeCard({
    super.key,
    required this.accountId,
    required this.onTap,
  });

  final String accountId;
  final Future<void> Function() onTap;

  @override
  State<WaterStreakHomeCard> createState() => _WaterStreakHomeCardState();
}

class _WaterStreakHomeCardState extends State<WaterStreakHomeCard>
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
  void didUpdateWidget(covariant WaterStreakHomeCard oldWidget) {
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
        final glasses = snapshot.data?.glassesToday ?? 0;
        final progress = (glasses / WaterStreakRepository.dailyGoal).clamp(
          0.0,
          1.0,
        );
        final message = snapshot.hasError
            ? 'No se pudo cargar. Toca para reintentar.'
            : snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData
            ? 'Cargando avance de hoy...'
            : _streakLabel(snapshot.data?.currentStreak ?? 0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('water-streak-home-card'),
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCEEF2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF164A5A).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: Color(0xFF2498B3),
                              size: 19,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'HIDRATACIÓN',
                              style: TextStyle(
                                color: const Color(0xFF1683A0),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Beber agua',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: AppTheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$glasses/${WaterStreakRepository.dailyGoal} vasos hoy · $message',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE8F3F5),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF38A9C1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Text(
                              'Un pequeño hábito, un gran avance',
                              style: TextStyle(
                                color: Color(0xFF1683A0),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: Color(0xFF1683A0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 62,
                    child: WaterProgressIllustration(
                      glasses: glasses,
                      height: 76,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _streakLabel(int days) => 'Racha $days ${days == 1 ? 'día' : 'días'}';
}
