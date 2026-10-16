import 'package:flutter/material.dart';
import '../../../../core/theme/motion.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/progress_repository.dart';

const double _minWeight = 30;
const double _maxWeight = 300;

/// Solo dígitos (hasta 3) con un decimal opcional separado por coma o punto.
final _numberFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) => RegExp(r'^\d{0,3}([.,]\d?)?$').hasMatch(newValue.text) ? newValue : oldValue,
);

Future<bool> showRegisterWeightSheet(
  BuildContext context, {
  double? lastWeight,
  double? height,
  ProgressRepository? repository,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    sheetAnimationStyle: kSheetAnimation,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) =>
        _RegisterWeightSheet(lastWeight: lastWeight, height: height, repository: repository ?? ProgressRepository()),
  );
  if (saved == true) MealLogState.instance.bump();
  return saved == true;
}

class _RegisterWeightSheet extends StatefulWidget {
  final double? lastWeight;
  final double? height;
  final ProgressRepository repository;

  const _RegisterWeightSheet({this.lastWeight, this.height, required this.repository});

  @override
  State<_RegisterWeightSheet> createState() => _RegisterWeightSheetState();
}

class _RegisterWeightSheetState extends State<_RegisterWeightSheet> {
  late final TextEditingController _weight = TextEditingController(text: _formatNumber(widget.lastWeight ?? 70, context.l10n));
  final TextEditingController _height = TextEditingController();
  String? _error;
  bool _saving = false;

  double? get _parsedWeight => double.tryParse(_weight.text.replaceAll(',', '.'));

  /// Un decimal; coma en español y punto en inglés.
  static String _formatNumber(double kg, AppLocalizations l10n) {
    final shown = kg.toStringAsFixed(1);
    return l10n.localeName == 'es' ? shown.replaceAll('.', ',') : shown;
  }

  /// Diferencia contra el último registro, p. ej. "+0,6 kg desde el último".
  String? _deltaText(AppLocalizations l10n) {
    final last = widget.lastWeight;
    final current = _parsedWeight;
    if (last == null || current == null) return null;
    final diff = ((current - last) * 10).round() / 10;
    if (diff == 0) return l10n.progressSheetSame;
    final shown = _formatNumber(diff.abs(), l10n);
    return diff > 0 ? l10n.progressSheetIncrease(shown) : l10n.progressSheetDecrease(shown);
  }

  void _step(double delta) {
    final current = _parsedWeight ?? widget.lastWeight ?? 70;
    final next = ((current + delta) * 10).round() / 10;
    _weight.text = _formatNumber(next.clamp(_minWeight, _maxWeight), context.l10n);
    setState(() {});
  }

  Future<void> _save() async {
    final weight = _parsedWeight;
    if (weight == null || weight < _minWeight || weight > _maxWeight) {
      setState(() => _error = context.l10n.progressSheetWeightRangeError);
      return;
    }
    final height = widget.height ?? double.tryParse(_height.text.replaceAll(',', '.'));
    if (height == null || height <= 0 || height > 300) {
      setState(() => _error = context.l10n.progressSheetHeightRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addWeight(weight: weight, height: height);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deltaText = _deltaText(l10n);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        // Si aparece un error, la hoja crece suave en vez de saltar.
        child: AnimatedSize(
          duration: kResizeDuration,
          curve: kResizeCurve,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.progressRegisterWeight,
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                widget.lastWeight == null
                    ? l10n.progressSheetHintNoLast
                    : l10n.progressSheetLastEntry(_formatNumber(widget.lastWeight!, l10n)),
                style: const TextStyle(color: Color(0xFF747779), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    _StepButton(tooltip: l10n.progressSheetSubtract, icon: Icons.remove_rounded, onPressed: () => _step(-0.1)),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 40, maxWidth: 140),
                                child: IntrinsicWidth(
                                  child: TextField(
                                    key: const ValueKey('weight-field'),
                                    controller: _weight,
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [_numberFormatter],
                                    onChanged: (_) => setState(() {}),
                                    cursorColor: AppTheme.primaryStart,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                      color: AppTheme.primaryStart,
                                    ),
                                    decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'kg',
                                style: TextStyle(color: Color(0xFF747779), fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if (deltaText != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              deltaText,
                              style: const TextStyle(
                                color: Color(0xFF747779),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StepButton(tooltip: l10n.progressSheetAdd, icon: Icons.add_rounded, onPressed: () => _step(0.1)),
                  ],
                ),
              ),
              if (widget.height == null) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('height-field'),
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_numberFormatter],
                  decoration: InputDecoration(
                    labelText: l10n.progressSheetHeightLabel,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryStart,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  child: Text(l10n.progressSheetSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _StepButton({required this.tooltip, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryStart,
        fixedSize: const Size(52, 52),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}
