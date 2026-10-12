import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Línea con los últimos pesos. Con menos de 2 no hay tendencia que mostrar.
class WeightSparkline extends StatelessWidget {
  final List<double> weights;

  const WeightSparkline({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.length < 2) return const SizedBox.shrink();
    return CustomPaint(painter: _SparklinePainter(weights));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> weights;

  _SparklinePainter(this.weights);

  @override
  void paint(Canvas canvas, Size size) {
    final minW = weights.reduce(math.min);
    final maxW = weights.reduce(math.max);
    final range = (maxW - minW).abs() < 0.01 ? 1 : maxW - minW;
    final path = Path();
    for (var i = 0; i < weights.length; i++) {
      final x = size.width * i / (weights.length - 1);
      final y = size.height - (size.height * (weights[i] - minW) / range);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryStart.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.weights != weights;
}
