/// Tarjetas interactivas que acompañan una respuesta del bot: el paso a paso
/// de la receta (opcionalmente abierto en un paso concreto) y un tip.
class ChatActions {
  final bool showSteps;

  /// Paso en el que se abre el paso a paso, empezando en 1.
  final int? focusStep;
  final String? tip;

  const ChatActions({this.showSteps = false, this.focusStep, this.tip});

  /// Null cuando no hay nada que mostrar, para no pintar tarjetas vacías.
  static ChatActions? fromMap(Object? map) {
    if (map is! Map) return null;

    final steps = map['steps'];
    final focus = steps is Map ? (steps['focus_step'] as num?)?.toInt() : null;
    final tip = (map['tip'] as String?)?.trim();

    final actions = ChatActions(
      showSteps: steps is Map,
      focusStep: focus != null && focus > 0 ? focus : null,
      tip: tip == null || tip.isEmpty ? null : tip,
    );
    return actions.showSteps || actions.tip != null ? actions : null;
  }
}
