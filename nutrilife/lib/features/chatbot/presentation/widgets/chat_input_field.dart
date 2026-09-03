import 'package:flutter/material.dart';
import '../../../nutrition/data/fridge_repository.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';
import 'fridge_picker_sheet.dart';

class ChatInputField extends StatefulWidget {
  final Future<void> Function(String message, List<FridgeItemModel> foods)
      onSend;
  final bool isLoading;
  final FridgeRepository? fridgeRepository;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
    this.fridgeRepository,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<FridgeItemModel> _attachedFoods = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFoods() async {
    if (widget.isLoading) return;

    final selection = await FridgePickerSheet.show(
      context,
      initialSelection: _attachedFoods,
      repository: widget.fridgeRepository,
    );
    if (selection == null || !mounted) return;

    setState(() => _attachedFoods = selection);
  }

  void _removeFood(FridgeItemModel item) {
    setState(() {
      _attachedFoods = _attachedFoods
          .where((i) => i.fridgeItemId != item.fridgeItemId)
          .toList();
    });
  }

  void _handleSend() {
    if (widget.isLoading) return;

    final message = _controller.text.trim();
    final foods = _attachedFoods;
    // Adjuntar alimentos sin escribir nada es una petición válida.
    if (message.isEmpty && foods.isEmpty) return;

    _controller.clear();
    setState(() => _attachedFoods = []);
    widget.onSend(message, foods);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachedFoods.isNotEmpty) _buildAttachedFoods(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickFoods,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _attachedFoods.isEmpty
                          ? Colors.transparent
                          : const Color(0xFFE8F3ED),
                      border: Border.all(
                        color: _attachedFoods.isEmpty
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF0A6B3F),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: _attachedFoods.isEmpty
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0A6B3F),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Mensaje a NutriLife...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.isLoading ? null : _handleSend,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isLoading
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0A6B3F),
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedFoods() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _attachedFoods.map((item) {
          return GestureDetector(
            onTap: () => _removeFood(item),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A6B3F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF0A6B3F),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
