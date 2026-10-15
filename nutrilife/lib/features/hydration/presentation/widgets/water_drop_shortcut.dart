import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/water_streak_repository.dart';

class WaterDropShortcut extends StatefulWidget {
  const WaterDropShortcut({
    super.key,
    required this.accountId,
    required this.onTap,
  });

  final String accountId;
  final Future<void> Function() onTap;

  @override
  State<WaterDropShortcut> createState() => _WaterDropShortcutState();
}

class _WaterDropShortcutState extends State<WaterDropShortcut>
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
  void didUpdateWidget(covariant WaterDropShortcut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _repository = WaterStreakRepository(accountId: widget.accountId);
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _snapshot = _repository.load();
    });
  }

  Future<void> _openTracker() async {
    await widget.onTap();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WaterStreakSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        final glasses = snapshot.data?.glassesToday ?? 0;
        final hasError = snapshot.hasError;
        return Semantics(
          button: true,
          label: hasError
              ? 'No se pudo cargar la racha de agua'
              : 'Racha de agua, $glasses de ${WaterStreakRepository.dailyGoal} vasos hoy',
          child: IconButton(
            key: const ValueKey('water-drop-shortcut'),
            tooltip: hasError
                ? 'No se pudo cargar; toca para ver opciones de recuperación'
                : 'Racha de agua',
            onPressed: _openTracker,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 46, height: 48),
            icon: SizedBox(
              width: 31,
              height: 40,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  end: glasses / WaterStreakRepository.dailyGoal,
                ),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, fill, _) =>
                    CustomPaint(painter: _WaterDropPainter(fill: fill)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  const _WaterDropPainter({required this.fill});

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final drop = Path()
      ..moveTo(size.width * 0.5, size.height * 0.06)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.22,
        size.width * 0.12,
        size.height * 0.53,
        size.width * 0.12,
        size.height * 0.69,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.91,
        size.width * 0.29,
        size.height * 0.98,
        size.width * 0.5,
        size.height * 0.98,
      )
      ..cubicTo(
        size.width * 0.71,
        size.height * 0.98,
        size.width * 0.88,
        size.height * 0.91,
        size.width * 0.88,
        size.height * 0.69,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.53,
        size.width * 0.58,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.06,
      )
      ..close();

    final fillRect = Rect.fromLTWH(
      0,
      size.height * (1 - fill.clamp(0, 1)),
      size.width,
      size.height * fill.clamp(0, 1),
    );
    canvas.save();
    canvas.clipPath(drop);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE6F5F9),
    );
    canvas.drawRect(fillRect, Paint()..color = const Color(0xFF39A9C1));
    canvas.restore();
    canvas.drawPath(
      drop,
      Paint()
        ..color = const Color(0xFF2488A2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.33, size.height * 0.56),
      Offset(size.width * 0.29, size.height * 0.69),
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) =>
      oldDelegate.fill != fill;
}
