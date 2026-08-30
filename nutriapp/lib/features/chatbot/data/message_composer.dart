import '../../nutrition/data/models/fridge_item_model.dart';

/// Unidades que no se escriben: "3 unidad de huevo" no lo dice nadie.
const _countableUnits = {'unidad', 'unidades', 'u', 'und', ''};

/// Pega los alimentos elegidos al final del mensaje.
///
/// El agente de intención de n8n extrae los ingredientes del texto plano,
/// así que adjuntarlos aquí basta para que la receta salga con lo que hay
/// en la nevera, sin tocar backend ni el flujo.
String buildMessageWithFoods(String message, List<FridgeItemModel> items) {
  final text = message.trim();
  if (items.isEmpty) return text;

  final list = items.map(_describe).join(', ');
  final foods = 'Tengo estos alimentos: $list.';

  return text.isEmpty ? foods : '$text\n\n$foods';
}

String _describe(FridgeItemModel item) {
  if (item.quantity <= 0) return item.name;

  final quantity = _formatQuantity(item.quantity);
  final unit = item.unit.trim().toLowerCase();
  if (_countableUnits.contains(unit)) return '$quantity ${item.name}';

  return '$quantity ${item.unit.trim()} de ${item.name}';
}

String _formatQuantity(double quantity) =>
    quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
