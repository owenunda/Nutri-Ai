import 'package:flutter/material.dart';
import '../../../nutrition/data/fridge_repository.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';

/// Hoja para elegir qué alimentos de la nevera se adjuntan al mensaje.
///
/// Devuelve la selección al cerrarse, o `null` si el usuario cancela.
class FridgePickerSheet extends StatefulWidget {
  final List<FridgeItemModel> initialSelection;
  final FridgeRepository? repository;

  const FridgePickerSheet({
    super.key,
    this.initialSelection = const [],
    this.repository,
  });

  static Future<List<FridgeItemModel>?> show(
    BuildContext context, {
    List<FridgeItemModel> initialSelection = const [],
    FridgeRepository? repository,
  }) {
    return showModalBottomSheet<List<FridgeItemModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => FridgePickerSheet(
        initialSelection: initialSelection,
        repository: repository,
      ),
    );
  }

  @override
  State<FridgePickerSheet> createState() => _FridgePickerSheetState();
}

class _FridgePickerSheetState extends State<FridgePickerSheet> {
  late final FridgeRepository _repository;
  final Set<int> _selectedIds = {};

  List<FridgeItemModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FridgeRepository();
    _selectedIds.addAll(widget.initialSelection.map((i) => i.fridgeItemId));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getFridgeItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggle(FridgeItemModel item) {
    setState(() {
      if (!_selectedIds.remove(item.fridgeItemId)) {
        _selectedIds.add(item.fridgeItemId);
      }
    });
  }

  void _confirm() {
    final selection =
        _items.where((i) => _selectedIds.contains(i.fridgeItemId)).toList();
    Navigator.of(context).pop(selection);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Alimentos de tu nevera',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2F31),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elige los que quieres incluir en tu mensaje.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: _buildBody(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _errorMessage != null ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B3F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedIds.isEmpty
                    ? 'Listo'
                    : 'Agregar ${_selectedIds.length} al mensaje',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A6B3F)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos leer tu nevera',
        detail: _errorMessage!,
        action: TextButton(
          onPressed: _load,
          child: const Text(
            'Reintentar',
            style: TextStyle(
              color: Color(0xFF0A6B3F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const _Message(
        icon: Icons.kitchen_outlined,
        title: 'Tu nevera está vacía',
        detail: 'Agrega alimentos desde la pestaña Alimentos y aparecerán aquí.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final item = _items[index];
        final selected = _selectedIds.contains(item.fridgeItemId);

        return InkWell(
          onTap: () => _toggle(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? const Color(0xFF0A6B3F)
                      : const Color(0xFFCBD5E1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2F31),
                    ),
                  ),
                ),
                if (item.quantity > 0)
                  Text(
                    '${formatFridgeQuantity(item.quantity)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sin esto las cantidades enteras se ven como "200.0 g".
String formatFridgeQuantity(double quantity) =>
    quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2F31),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          ?action,
        ],
      ),
    );
  }
}
