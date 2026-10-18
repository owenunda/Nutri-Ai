import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/water_streak_repository.dart';
import '../widgets/water_progress_illustration.dart';

class WaterStreakScreen extends StatefulWidget {
  const WaterStreakScreen({super.key, required this.accountId});

  final String accountId;

  @override
  State<WaterStreakScreen> createState() => _WaterStreakScreenState();
}

class _WaterStreakScreenState extends State<WaterStreakScreen>
    with WidgetsBindingObserver {
  late final WaterStreakRepository _repository = WaterStreakRepository(
    accountId: widget.accountId,
  );
  WaterStreakSnapshot? _snapshot;
  Object? _loadError;
  Object? _saveError;
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _midnightRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightRefresh?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightRefresh?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightRefresh = Timer(delay, () {
      unawaited(_load());
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final snapshot = await _repository.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeGlasses({required bool add}) async {
    if (_isSaving || _snapshot == null) return;
    final goalWasCompleted = _snapshot!.goalCompleted;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final snapshot = add
          ? await _repository.addGlass()
          : await _repository.undoGlass();
      if (!mounted) return;
      final showCelebration =
          add && !goalWasCompleted && snapshot.goalCompleted;
      setState(() {
        _snapshot = snapshot;
        _isSaving = false;
      });
      if (showCelebration) {
        unawaited(_showGoalCelebration());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error;
        _isSaving = false;
      });
    }
  }

  Future<void> _showGoalCelebration() {
    return showDialog<void>(
      context: context,
      builder: (_) => const _WaterGoalCelebrationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F8FA),
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.hydrationScreenTitle,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2799B5)),
              )
            : _loadError != null
            ? _buildLoadError()
            : _buildTracker(_snapshot!),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: Color(0xFF6A8790),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.hydrationLoadError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _load,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracker(WaterStreakSnapshot snapshot) {
    final l10n = context.l10n;
    final remaining = WaterStreakRepository.dailyGoal - snapshot.glassesToday;
    final completed = snapshot.goalCompleted;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStreakCard(snapshot),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF164A5A).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.hydrationTodayChallenge,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${snapshot.glassesToday}/${WaterStreakRepository.dailyGoal}',
                      style: const TextStyle(
                        color: Color(0xFF1683A0),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value:
                        snapshot.glassesToday /
                        WaterStreakRepository.dailyGoal,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE5F1F4),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF37A8C1),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                WaterProgressIllustration(
                  glasses: snapshot.glassesToday,
                  height: 220,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _dialogue(l10n, snapshot.glassesToday),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF45626C),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('add-water-glass'),
                    onPressed: _isSaving || completed
                        ? null
                        : () => _changeGlasses(add: true),
                    icon: Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.water_drop_rounded,
                    ),
                    label: Text(
                      completed ? l10n.hydrationChallengeDone : l10n.hydrationLogGlass,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1683A0),
                      disabledBackgroundColor: const Color(0xFF1683A0),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (snapshot.glassesToday > 0) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _changeGlasses(add: false),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: Text(l10n.hydrationUndoGlass),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5F7C86),
                    ),
                  ),
                ],
                if (_saveError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.hydrationSaveError(
                      _saveError.toString().replaceFirst('Exception: ', ''),
                    ),
                    key: const ValueKey('water-save-error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (!completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.hydrationRemaining(remaining),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF738991),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.hydrationGoalNote(WaterStreakRepository.dailyGoal),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF738991),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(WaterStreakSnapshot snapshot) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14677A), Color(0xFF269BB2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14677A).withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFFD486),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hydrationCurrentStreakKicker,
                  style: const TextStyle(
                    color: Color(0xFFD3F2F7),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.hydrationDays(snapshot.currentStreak),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  l10n.hydrationBestStreak(snapshot.bestStreak),
                  style: const TextStyle(
                    color: Color(0xFFD3F2F7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.waves_rounded,
            color: Color(0xFFB5E9F1),
            size: 34,
          ),
        ],
      ),
    );
  }

  String _dialogue(AppLocalizations l10n, int glasses) {
    return switch (glasses) {
      0 => l10n.hydrationDialogue0,
      1 => l10n.hydrationDialogue1,
      2 => l10n.hydrationDialogue2,
      3 => l10n.hydrationDialogue3,
      4 => l10n.hydrationDialogue4,
      _ => l10n.hydrationDialogueDone,
    };
  }
}

class _WaterGoalCelebrationDialog extends StatelessWidget {
  const _WaterGoalCelebrationDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.82, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Image.asset(
                'assets/images/nutria_celebracion.png',
                width: 210,
                height: 190,
                fit: BoxFit.contain,
                semanticLabel: l10n.hydrationCelebrationImage,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.hydrationGoalReached,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF14677A),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.hydrationCelebrationBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F7C86),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1683A0),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  l10n.hydrationCelebrationOk,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
