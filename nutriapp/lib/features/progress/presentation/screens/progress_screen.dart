import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/progress_repository.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.user,
    this.refreshToken = 0,
  });

  final Map<String, dynamic>? user;
  final int refreshToken;

  static const Color _text = AppTheme.onSurface;
  static const Color _muted = AppTheme.onSurfaceVariant;
  static const Color _green = AppTheme.primaryStart;
  static const Color _mint = Color(0xFF69E7A4);
  static const Color _blue = AppTheme.tertiary;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressRepository _repository;
  late Future<ProgressData> _progressFuture;

  @override
  void initState() {
    super.initState();
    _repository = ProgressRepository();
    _progressFuture = _repository.fetchProgress();
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _progressFuture = _repository.fetchProgress();
    }
  }

  Future<void> _refreshProgress() async {
    setState(() {
      _progressFuture = _repository.fetchProgress();
    });

    await _progressFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgressData>(
      future: _progressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProgressLoadingView();
        }

        if (snapshot.hasError) {
          return _ProgressErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshProgress,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return _ProgressErrorView(
            message: 'No se pudo cargar tu progreso.',
            onRetry: _refreshProgress,
          );
        }

        return RefreshIndicator(
          color: ProgressScreen._green,
          onRefresh: _refreshProgress,
          child: _ProgressContent(data: data),
        );
      },
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProgressHeader(),
          const SizedBox(height: 38),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESO SEMANAL',
                      style: GoogleFonts.inter(
                        color: ProgressScreen._green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Buen progreso,\n${data.firstName}!',
                      style: GoogleFonts.plusJakartaSans(
                        color: ProgressScreen._text,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _GoalPill(goal: data.goalLabel),
            ],
          ),
          const SizedBox(height: 18),
          _WeightInsightCard(data: data),
          const SizedBox(height: 18),
          _TodayCaloriesCard(data: data),
          const SizedBox(height: 22),
          _WeightHistoryCard(
            records: data.orderedHistory,
            currentWeight: data.currentWeight,
          ),
          const SizedBox(height: 28),
          Text(
            'Resumen nutricional',
            style: GoogleFonts.plusJakartaSans(
              color: ProgressScreen._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _NutritionAveragesGrid(data: data),
        ],
      ),
    );
  }
}

class _ProgressLoadingView extends StatelessWidget {
  const _ProgressLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        children: [
          _ProgressHeader(),
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(color: ProgressScreen._green),
          ),
        ],
      ),
    );
  }
}

class _ProgressErrorView extends StatelessWidget {
  const _ProgressErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        children: [
          const _ProgressHeader(),
          const SizedBox(height: 80),
          _ProgressCard(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB42318).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB42318),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar tu progreso',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  textButton: 'Intentar de nuevo',
                  icon: Icons.refresh_rounded,
                  height: 48,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF25313B),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'NutriAI',
          style: GoogleFonts.plusJakartaSans(
            color: ProgressScreen._green,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.notifications_rounded,
          color: Color(0xFF94A3B8),
          size: 23,
        ),
      ],
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.goal});

  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: ProgressScreen._mint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        'Meta:\n$goal',
        style: GoogleFonts.inter(
          color: const Color(0xFF064D31),
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeightInsightCard extends StatelessWidget {
  const _WeightInsightCard({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final change = data.latestWeightChange;
    final hasChange = change != null;
    final currentWeight = data.currentWeight;
    final isDown = hasChange && change < 0;
    final isUp = hasChange && change > 0;
    final icon = isDown
        ? Icons.trending_down_rounded
        : isUp
        ? Icons.trending_up_rounded
        : Icons.trending_flat_rounded;
    final mainText = _weightInsightText(change);
    final highlightedText = hasChange
        ? '${change.abs().toStringAsFixed(1)}kg'
        : '';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 164),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -14,
            child: SizedBox(
              width: 120,
              height: 90,
              child: CustomPaint(painter: _InsightChartPainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: ProgressScreen._green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Resumen de peso',
                    style: GoogleFonts.plusJakartaSans(
                      color: ProgressScreen._green,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (hasChange)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: mainText.$1),
                      TextSpan(
                        text: highlightedText,
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                      TextSpan(text: mainText.$2),
                    ],
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Peso actual\n'),
                      TextSpan(
                        text: currentWeight == null
                            ? 'Sin registro'
                            : '${_formatDouble(currentWeight)}kg',
                        style: const TextStyle(color: ProgressScreen._green),
                      ),
                    ],
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                hasChange
                    ? 'Comparado con tu registro físico anterior.'
                    : 'Registra otro peso más adelante para ver tu evolución.',
                style: GoogleFonts.inter(
                  color: ProgressScreen._muted.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, String) _weightInsightText(double? change) {
    if (change == null) {
      return ('', '');
    }

    if (change < 0) {
      return ('Tu peso bajo\n', ' desde el registro anterior');
    }

    if (change > 0) {
      return ('Tu peso subio\n', ' desde el registro anterior');
    }

    return ('Tu peso cambio\n', ' desde el registro anterior');
  }
}

class _TodayCaloriesCard extends StatelessWidget {
  const _TodayCaloriesCard({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final dailyLimit = data.dailyLimit;
    final remaining = data.remaining;

    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Calorias de hoy',
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(status: data.status),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatInt(data.totalConsumed),
                style: GoogleFonts.plusJakartaSans(
                  color: ProgressScreen._green,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  dailyLimit == null
                      ? 'kcal consumidas'
                      : 'de ${_formatInt(dailyLimit)} kcal',
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.calorieProgress,
              minHeight: 12,
              backgroundColor: const Color(0xFFDDE4E8),
              valueColor: AlwaysStoppedAnimation<Color>(
                data.status.toUpperCase() == 'EXCEDIDO'
                    ? const Color(0xFFB42318)
                    : ProgressScreen._green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dailyLimit == null || remaining == null
                ? 'Completa tus datos físicos y tu meta para calcular tu límite diario.'
                : 'Meta diaria: ${_formatInt(dailyLimit)} kcal. Te quedan ${_formatInt(remaining)} kcal disponibles hoy.',
            style: GoogleFonts.inter(
              color: ProgressScreen._muted.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isExceeded = status.toUpperCase() == 'EXCEDIDO';
    final color = isExceeded ? const Color(0xFFB42318) : ProgressScreen._green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({
    required this.records,
    required this.currentWeight,
  });

  final List<PhysicalRecord> records;
  final double? currentWeight;

  @override
  Widget build(BuildContext context) {
    final validRecords = records
        .where((record) => record.weight != null)
        .toList();

    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Historial de peso',
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: ProgressScreen._blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentWeight == null
                    ? 'Sin peso actual'
                    : '${_formatDouble(currentWeight!)}kg Actual',
                style: GoogleFonts.inter(
                  color: ProgressScreen._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: validRecords.isEmpty
                ? const _EmptyHistoryState()
                : CustomPaint(
                    painter: _WeightHistoryPainter(records: validRecords),
                  ),
          ),
          if (validRecords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _historyLabels(
                validRecords,
              ).map((label) => _AxisLabel(label)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aún no tienes historial físico.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: ProgressScreen._muted.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NutritionAveragesGrid extends StatelessWidget {
  const _NutritionAveragesGrid({required this.data});

  final ProgressData data;

  @override
  Widget build(BuildContext context) {
    final dailyLimit = data.dailyLimit;
    final remaining = data.remaining;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AverageTile(
                label: 'CONSUMIDAS',
                value: '${_formatInt(data.totalConsumed)} kcal',
                detail: 'Registradas hoy',
                accent: ProgressScreen._green,
                progress: data.calorieProgress,
                highlighted: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AverageTile(
                label: 'META DIARIA',
                value: dailyLimit == null
                    ? '--'
                    : '${_formatInt(dailyLimit)} kcal',
                accent: ProgressScreen._green,
                progress: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AverageTile(
                label: 'RESTANTES',
                value: remaining == null
                    ? '--'
                    : '${_formatInt(remaining)} kcal',
                accent: const Color(0xFF0F7C86),
                progress: 1 - data.calorieProgress,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AverageTile(
                label: 'ESTADO',
                value: data.status,
                accent: data.status.toUpperCase() == 'EXCEDIDO'
                    ? const Color(0xFFB42318)
                    : ProgressScreen._blue,
                progress: data.status.toUpperCase() == 'EXCEDIDO'
                    ? 1
                    : data.calorieProgress,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AverageTile extends StatelessWidget {
  const _AverageTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.progress,
    this.detail,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String? detail;
  final Color accent;
  final double progress;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Stack(
        children: [
          if (highlighted)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: ProgressScreen._green,
                child: SizedBox(width: 3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: ProgressScreen._muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: ProgressScreen._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail!,
                    style: GoogleFonts.inter(
                      color: ProgressScreen._green,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1).toDouble(),
                      minHeight: 4,
                      backgroundColor: const Color(0xFFD6DEE3),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: child,
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: const Color(0xFF9AA4AF),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _InsightChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square;
    final linePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (var i = 0; i < 4; i++) {
      final x = 14.0 + (i * 26);
      final top = size.height - (24.0 + i * 11);
      canvas.drawLine(Offset(x, size.height), Offset(x, top), barPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.28, size.height * 0.72)
      ..lineTo(size.width * 0.52, size.height * 0.35)
      ..lineTo(size.width * 0.72, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.18);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeightHistoryPainter extends CustomPainter {
  const _WeightHistoryPainter({required this.records});

  final List<PhysicalRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final weights = records.map((record) => record.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight == 0 ? 1 : maxWeight - minWeight;
    final points = <Offset>[];

    for (var index = 0; index < weights.length; index++) {
      final x = weights.length == 1
          ? size.width * 0.5
          : size.width * (index / (weights.length - 1));
      final normalized = (weights[index] - minWeight) / range;
      final y = size.height * 0.78 - (normalized * size.height * 0.58);
      points.add(Offset(x, y));
    }

    final paint = Paint()
      ..color = ProgressScreen._blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    final dotFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..color = ProgressScreen._blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotFill);
      canvas.drawCircle(point, 4, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightHistoryPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}

List<String> _historyLabels(List<PhysicalRecord> records) {
  final recordsWithDate = records
      .where((record) => record.recordDate != null)
      .toList();
  if (recordsWithDate.isEmpty) {
    return const ['INICIO', 'HOY'];
  }

  if (recordsWithDate.length <= 5) {
    return recordsWithDate
        .map((record) => _formatDate(record.recordDate!))
        .toList();
  }

  final indexes = <int>{
    0,
    (recordsWithDate.length * 0.25).round(),
    (recordsWithDate.length * 0.50).round(),
    (recordsWithDate.length * 0.75).round(),
    recordsWithDate.length - 1,
  }.toList()..sort();

  return indexes
      .map(
        (index) =>
            recordsWithDate[index.clamp(0, recordsWithDate.length - 1).toInt()],
      )
      .map((record) => _formatDate(record.recordDate!))
      .toList();
}

String _formatDate(DateTime date) {
  const months = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  return '${months[date.month - 1]} ${date.day}';
}

String _formatDouble(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < text.length; index++) {
    final remaining = text.length - index;
    buffer.write(text[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
