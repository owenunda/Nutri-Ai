import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/sheet_insets.dart';
import '../../../nutrition/data/food_repository.dart';
import '../../../nutrition/data/fridge_repository.dart';
import '../../../nutrition/data/models/food_model.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';
import '../../../nutrition/domain/food_units.dart';

/// Hoja para elegir qué alimentos se adjuntan al mensaje: los de la nevera o
/// los alimentos comunes del catálogo, cada grupo en su pestaña.
///
/// Devuelve la selección al cerrarse, o `null` si el usuario cancela. Los
/// comunes vuelven como [FridgeItemModel] sin `fridgeItemId` (ver
/// [FridgeItemModel.isFromFridge]).
class FridgePickerSheet extends StatefulWidget {
  final List<FridgeItemModel> initialSelection;
  final FridgeRepository? repository;
  final FoodRepository? foodRepository;

  const FridgePickerSheet({
    super.key,
    this.initialSelection = const [],
    this.repository,
    this.foodRepository,
  });

  static Future<List<FridgeItemModel>?> show(
    BuildContext context, {
    List<FridgeItemModel> initialSelection = const [],
    FridgeRepository? repository,
    FoodRepository? foodRepository,
  }) {
    return showModalBottomSheet<List<FridgeItemModel>>(
      context: context,
      sheetAnimationStyle: kSheetAnimation,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => FridgePickerSheet(
        initialSelection: initialSelection,
        repository: repository,
        foodRepository: foodRepository,
      ),
    );
  }

  @override
  State<FridgePickerSheet> createState() => _FridgePickerSheetState();
}

class _FridgePickerSheetState extends State<FridgePickerSheet> {
  late final FridgeRepository _repository;
  late final FoodRepository _foodRepository;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedKeys = {};

  List<FridgeItemModel> _items = [];
  List<FridgeItemModel> _common = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Nevera y comunes van en pestañas para que la lista no se haga eterna.
  bool _showCommon = false;

  /// La nevera y el catálogo pueden traer el mismo id numérico.
  static String _key(FridgeItemModel item) =>
      item.isFromFridge ? 'n${item.fridgeItemId}' : 'c${item.foodId}';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FridgeRepository();
    _foodRepository = widget.foodRepository ?? FoodRepository();
    _selectedKeys.addAll(widget.initialSelection.map(_key));
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Sin catálogo la hoja sigue sirviendo con la nevera.
    final commonFuture =
        _foodRepository.getFoods().catchError((_) => <FoodModel>[]);
    try {
      final items = await _repository.getFridgeItems();
      final inFridge = items.map((i) => i.foodId).toSet();
      final common = (await commonFuture)
          .where((f) => f.isGlobal && !inFridge.contains(f.foodId))
          .map((f) => FridgeItemModel(
                fridgeItemId: 0,
                foodId: f.foodId,
                name: f.name,
                quantity: 0,
                unit: '',
                caloriesPerUnit: f.caloriesPerUnit,
                baseUnit: f.baseUnit,
              ))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _items = items;
        _common = common;
        _isLoading = false;
        // Con la nevera vacía no tiene sentido abrir en ella.
        _showCommon = items.isEmpty && common.isNotEmpty;
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
      final key = _key(item);
      if (!_selectedKeys.remove(key)) _selectedKeys.add(key);
    });
  }

  void _confirm() {
    final selection = [..._items, ..._common]
        .where((i) => _selectedKeys.contains(_key(i)))
        .toList();
    Navigator.of(context).pop(selection);
  }

  List<FridgeItemModel> _filter(List<FridgeItemModel> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((i) => i.name.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + sheetBottomInset(context)),
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
          Text(
            context.l10n.chatPickerTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2F31),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.chatPickerIntro,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF64748B), height: 1.35),
          ),
          if (!_isLoading && _errorMessage == null) ...[
            const SizedBox(height: 16),
            SegmentedTabs(
              labels: [
                context.l10n.chatPickerTabFridge,
                context.l10n.chatPickerTabCommon,
              ],
              badges: [
                _items.where((i) => _selectedKeys.contains(_key(i))).length,
                _common.where((i) => _selectedKeys.contains(_key(i))).length,
              ],
              selected: _showCommon ? 1 : 0,
              onChanged: (index) => setState(() => _showCommon = index == 1),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _showCommon
                    ? context.l10n.chatPickerSearchCommon
                    : context.l10n.chatPickerSearchFridge,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8)),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Flexible: en pantallas bajas (o con teclado) la lista cede espacio
          // y hace scroll, en vez de desbordar la hoja.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              // Al cambiar de pestaña o buscar, el alto se acomoda sin saltos.
              child: AnimatedSize(
                duration: kResizeDuration,
                curve: kResizeCurve,
                alignment: Alignment.topCenter,
                child: _buildBody(),
              ),
            ),
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
                _selectedKeys.isEmpty
                    ? context.l10n.commonDone
                    : context.l10n.chatPickerAddCount(_selectedKeys.length),
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
        title: context.l10n.chatPickerErrorTitle,
        detail: _errorMessage!,
        action: TextButton(
          onPressed: _load,
          child: Text(
            context.l10n.commonRetry,
            style: const TextStyle(
              color: Color(0xFF0A6B3F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final query = _searchController.text.trim();
    final visible = _filter(_showCommon ? _common : _items);

    if (visible.isEmpty) {
      final elsewhere = _filter(_showCommon ? _items : _common).length;
      if (query.isNotEmpty) {
        return _Message(
          icon: Icons.search_off_rounded,
          title: context.l10n.chatPickerNoResults,
          detail: _showCommon
              ? context.l10n.chatPickerNoResultsCommon(query)
              : context.l10n.chatPickerNoResultsFridge(query),
          action: elsewhere == 0
              ? null
              : TextButton(
                  onPressed: () => setState(() => _showCommon = !_showCommon),
                  child: Text(
                    _showCommon
                        ? context.l10n.chatPickerSeeInFridge(elsewhere)
                        : context.l10n.chatPickerSeeInCommon(elsewhere),
                    style: const TextStyle(
                      color: Color(0xFF0A6B3F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        );
      }
      return _showCommon
          ? _Message(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.chatPickerCommonEmptyTitle,
              detail: context.l10n.chatPickerCommonEmptyBody,
            )
          : _Message(
              icon: Icons.kitchen_outlined,
              title: context.l10n.chatPickerFridgeEmptyTitle,
              detail: context.l10n.chatPickerFridgeEmptyBody,
            );
    }

    return ListView(
      shrinkWrap: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [for (final item in visible) _row(item)],
    );
  }

  Widget _row(FridgeItemModel item) => Column(
        children: [
          _FoodRow(
            item: item,
            selected: _selectedKeys.contains(_key(item)),
            onTap: () => _toggle(item),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      );
}

class _FoodRow extends StatelessWidget {
  final FridgeItemModel item;
  final bool selected;
  final VoidCallback onTap;

  const _FoodRow(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color:
                  selected ? const Color(0xFF0A6B3F) : const Color(0xFFCBD5E1),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2F31),
                    ),
                  ),
                  if (item.hasCalories) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.caloriesPerUnit.toInt()} kcal · ${prettyUnitLabel(item.baseUnit, context.l10n)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Los comunes no están en la nevera: no hay cantidad que mostrar.
            if (item.isFromFridge)
              item.quantity > 0
                  ? Text(
                      formatQuantityWithUnit(item.quantity, item.unit, context.l10n),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2C2F31),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      context.l10n.chatPickerNoAmount,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

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
