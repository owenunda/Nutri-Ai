import 'package:flutter/material.dart';

class AnalyzeProgressScreen extends StatefulWidget {
  const AnalyzeProgressScreen({super.key});

  @override
  State<AnalyzeProgressScreen> createState() => _AnalyzeProgressScreenState();
}

class _AnalyzeProgressScreenState extends State<AnalyzeProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartAnimationController;

  @override
  void initState() {
    super.initState();

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Espaciador superior
                const SizedBox(height: 56),

                const Spacer(),

                // =========================
                // Ilustración de progreso
                // =========================
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,

                    children: [
                      // Tarjeta principal
                      Container(
                        width: 300,
                        height: 300,

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(40),

                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.04),

                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),

                        padding: const EdgeInsets.all(24),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                Container(
                                  width: 80,
                                  height: 12,

                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),

                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),

                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0A6B3F,
                                    ).withValues(alpha: 0.1),

                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  child: const Text(
                                    '+24%',
                                    style: TextStyle(
                                      color: Color(0xFF0A6B3F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            Expanded(
                              child: AnimatedBuilder(
                                animation: _chartAnimationController,

                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(double.infinity, 120),

                                    painter: ProgressChartPainter(
                                      progress: _chartAnimationController.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =========================
                      // Trofeo verde premium
                      // =========================
                      Positioned(
                        top: -16,
                        right: -10,

                        child: Container(
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: const Color(0xFFDDE8D5),

                            borderRadius: BorderRadius.circular(24),

                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0A6B3F,
                                ).withValues(alpha: 0.12),

                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFF0A6B3F),
                            size: 32,
                          ),
                        ),
                      ),

                      // =========================
                      // Tarjeta Meta Cumplida
                      // =========================
                      Positioned(
                        bottom: 16,
                        right: 16,

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.05),

                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),

                          child: const Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF0A6B3F),
                                size: 18,
                              ),

                              SizedBox(width: 8),

                              Text(
                                'META CUMPLIDA',
                                style: TextStyle(
                                  color: Color(0xFF2C2F31),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // =========================
                // Textos inferiores
                // =========================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),

                  child: Column(
                    children: [
                      Text(
                        'Analiza tu Progreso',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Color(0xFF2C2F31),
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 16),

                      Text(
                        'Mantente motivado con información detallada sobre tus hábitos. Revisa tus tendencias y celebra cada logro en tu camino.',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Color(0xFF595C5E),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Espacio inferior
                const SizedBox(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressChartPainter extends CustomPainter {
  final double progress;

  ProgressChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A6B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final points = [
      Offset(10, size.height * 0.8),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.45, size.height * 0.85),
      Offset(size.width * 0.65, size.height * 0.55),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width * 0.95, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);

      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    final pathMetrics = path.computeMetrics().toList();

    if (pathMetrics.isEmpty) return;

    final extractPath = Path();

    for (final metric in pathMetrics) {
      extractPath.addPath(
        metric.extractPath(0.0, metric.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(extractPath, paint);

    if (progress > 0) {
      final lastMetric = pathMetrics.last;

      final tangent = lastMetric.getTangentForOffset(
        lastMetric.length * progress,
      );

      if (tangent != null) {
        final dotPaint = Paint()
          ..color = const Color(0xFF0A6B3F)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(tangent.position, 6.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
