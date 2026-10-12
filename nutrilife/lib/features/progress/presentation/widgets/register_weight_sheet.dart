import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/progress_repository.dart';

const double _minWeight = 30;
const double _maxWeight = 300;

Future<bool> showRegisterWeightSheet(
  BuildContext context, {
  double? lastWeight,
  double? height,
  ProgressRepository? repository,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _RegisterWeightSheet(
      lastWeight: lastWeight,
      height: height,
      repository: repository ?? ProgressRepository(),
    ),
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
  late final TextEditingController _weight =
      TextEditingController(text: (widget.lastWeight ?? 70).toStringAsFixed(1));
  final TextEditingController _height = TextEditingController();
  String? _error;
  bool _saving = false;

  double? get _parsedWeight => double.tryParse(_weight.text.replaceAll(',', '.'));

  void _step(double delta) {
    final current = _parsedWeight ?? widget.lastWeight ?? 70;
    final next = ((current + delta) * 10).round() / 10;
    _weight.text = next.clamp(_minWeight, _maxWeight).toStringAsFixed(1);
    setState(() {});
  }

  Future<void> _save() async {
    final weight = _parsedWeight;
    if (weight == null || weight < _minWeight || weight > _maxWeight) {
      setState(() => _error = 'El peso debe estar entre 30 y 300 kg');
      return;
    }
    final height = widget.height ?? double.tryParse(_height.text.replaceAll(',', '.'));
    if (height == null || height <= 0 || height > 300) {
      setState(() => _error = 'Ingresa tu altura en cm');
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar peso',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Restar 0,1 kg',
                  onPressed: () => _step(-0.1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('weight-field'),
                    controller: _weight,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryStart),
                    decoration: const InputDecoration(border: InputBorder.none, suffixText: 'kg'),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Sumar 0,1 kg',
                  onPressed: () => _step(0.1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (widget.height == null) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('height-field'),
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Altura (cm)',
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
                child: const Text('Guardar peso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
