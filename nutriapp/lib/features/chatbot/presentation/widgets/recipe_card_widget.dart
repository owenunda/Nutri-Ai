import 'package:flutter/material.dart';
import '../../data/models/recipe_model.dart';

class RecipeCardWidget extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeCardWidget({super.key, required this.recipe});

  @override
  State<RecipeCardWidget> createState() => _RecipeCardWidgetState();
}

class _RecipeCardWidgetState extends State<RecipeCardWidget> {
  bool _expandSummary = false;

  static const _green = Color(0xFF0A6B3F);
  static const _lightGreen = Color(0xFF16A34A);
  static const _slate = Color(0xFF64748B);
  static const _dark = Color(0xFF1A1A2E);

  void _openStepsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeStepsModal(recipe: widget.recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Container(
      margin: const EdgeInsets.only(left: 38, top: 6, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(recipe: recipe),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: _slate),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.preparationTimeMinutes} min',
                          style: const TextStyle(
                              fontSize: 12,
                              color: _slate,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Tag(recipe.mealType.toUpperCase(), _green),
                    _Tag(recipe.difficulty.toUpperCase(),
                        const Color(0xFF0284C7)),
                    _Tag('${recipe.servings} PORC.',
                        const Color(0xFF7C3AED)),
                  ],
                ),
                const SizedBox(height: 10),
                // Summary with "ver más"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.summary,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _slate,
                        height: 1.45,
                      ),
                      maxLines: _expandSummary ? null : 3,
                      overflow: _expandSummary
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expandSummary = !_expandSummary),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _expandSummary ? 'Ver menos' : 'Ver más',
                          style: const TextStyle(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Primary button — opens step modal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openStepsModal(context),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Ver receta completa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Secondary button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agregar al log diario'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _lightGreen,
                      side: const BorderSide(color: _lightGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
}

// ── Step-by-step modal ────────────────────────────────────────────────────────

class _RecipeStepsModal extends StatefulWidget {
  final RecipeModel recipe;

  const _RecipeStepsModal({required this.recipe});

  @override
  State<_RecipeStepsModal> createState() => _RecipeStepsModalState();
}

class _RecipeStepsModalState extends State<_RecipeStepsModal> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _green = Color(0xFF0A6B3F);

  // All "pages": steps + one tips page (if any)
  late final int _totalPages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final hasTips = widget.recipe.tips.isNotEmpty;
    _totalPages =
        widget.recipe.steps.length + (hasTips ? 1 : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isLastPage = _currentPage == _totalPages - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _currentPage < recipe.steps.length
                      ? 'Paso ${_currentPage + 1} de ${recipe.steps.length}'
                      : 'Tips',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                if (index < recipe.steps.length) {
                  return _StepPage(
                    step: recipe.steps[index],
                    total: recipe.steps.length,
                  );
                }
                // Tips page
                return _TipsPage(tips: recipe.tips);
              },
            ),
          ),
          // Dots indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _green
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Nav buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                if (_currentPage > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      isLastPage
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label:
                        Text(isLastPage ? 'Listo' : 'Siguiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
}

class _StepPage extends StatelessWidget {
  final RecipeStep step;
  final int total;

  const _StepPage({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A6B3F).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF0A6B3F), width: 2),
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A6B3F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A2E),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Swipe hint (only on first page)
          if (step.step == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swipe_rounded,
                    size: 14, color: Color(0xFFCBD5E1)),
                const SizedBox(width: 5),
                Text(
                  'Desliza para continuar',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF64748B).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipsPage extends StatelessWidget {
  final List<String> tips;

  const _TipsPage({required this.tips});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tips_and_updates_rounded,
                  color: Color(0xFF0A6B3F), size: 22),
              SizedBox(width: 8),
              Text(
                'Tips del chef',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...tips.asMap().entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0A6B3F).withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0A6B3F),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Card sub-widgets ──────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final RecipeModel recipe;

  const _HeaderSection({required this.recipe});

  IconData _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'desayuno':
        return Icons.free_breakfast_rounded;
      case 'almuerzo':
      case 'comida':
        return Icons.lunch_dining_rounded;
      case 'cena':
        return Icons.dinner_dining_rounded;
      case 'snack':
      case 'merienda':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064E2F), Color(0xFF0A6B3F), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Icon(
              _mealIcon(recipe.mealType),
              size: 72,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.orange, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.estimatedCalories} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_outlined,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.servings} porciones',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
