import 'package:flutter/material.dart';
import '../../data/models/chat_actions_model.dart';
import '../../data/models/recipe_model.dart';
import 'recipe_card_widget.dart';

/// Tarjetas interactivas bajo una respuesta del bot: abrir el paso a paso de
/// la receta y un tip destacado.
class AnswerActions extends StatelessWidget {
  final ChatActions actions;

  /// Receta de la conversación. Sin ella (o sin pasos) no hay paso a paso.
  final RecipeModel? recipe;

  const AnswerActions({super.key, required this.actions, this.recipe});

  @override
  Widget build(BuildContext context) {
    final recipe = this.recipe;
    final canShowSteps =
        actions.showSteps && recipe != null && recipe.steps.isNotEmpty;

    return Padding(
      // Alineado con la burbuja, después del avatar del bot.
      padding: const EdgeInsets.only(left: 38, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canShowSteps)
            _StepsCard(recipe: recipe, focusStep: actions.focusStep),
          if (canShowSteps && actions.tip != null) const SizedBox(height: 8),
          if (actions.tip != null) _TipCard(tip: actions.tip!),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final RecipeModel recipe;
  final int? focusStep;

  const _StepsCard({required this.recipe, this.focusStep});

  static const _green = Color(0xFF0A6B3F);

  @override
  Widget build(BuildContext context) {
    final count = recipe.steps.length;
    final minutes = recipe.preparationTimeMinutes;
    final subtitle = [
      '$count ${count == 1 ? 'paso' : 'pasos'}',
      if (minutes > 0) '$minutes min',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: _green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focusStep != null ? 'Paso $focusStep' : 'Paso a paso',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.title} · $subtitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => showRecipeStepsSheet(
              context,
              recipe,
              initialStep: focusStep ?? 1,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Ver paso a paso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tip del chef',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
