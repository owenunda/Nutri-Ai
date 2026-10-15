import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/local_date.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/data/models/day_meals.dart';
import '../../../meals/presentation/widgets/day_meals_list.dart';
import '../../../meals/presentation/widgets/meal_detail_sheet.dart';
import '../../../progress/data/progress_repository.dart';
import '../../../nutrition/presentation/screens/all_foods_screen.dart';

/// "Comidas de hoy" con lo que el usuario registró de verdad.
class TodayMealsSection extends StatefulWidget {
  final MealRepository? repository;
  final ProgressRepository? progressRepository;
  final DateTime Function()? clock;
  final VoidCallback? onOpenHistory;

  const TodayMealsSection({
    super.key,
    this.repository,
    this.progressRepository,
    this.clock,
    this.onOpenHistory,
  });

  @override
  State<TodayMealsSection> createState() => _TodayMealsSectionState();
}

class _TodayMealsSectionState extends State<TodayMealsSection> {
  late final MealRepository _repository = widget.repository ?? MealRepository();
  late final ProgressRepository _progressRepository =
      widget.progressRepository ?? ProgressRepository();
  late Future<DayMeals> _future;
  late Future<int?> _dailyLimitFuture;

  String get _today => localDateString((widget.clock ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _future = _repository.getDay(_today);
    _dailyLimitFuture = _progressRepository.fetchDailyLimit();
    MealLogState.instance.addListener(_reload);
  }

  @override
  void dispose() {
    MealLogState.instance.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _repository.getDay(_today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comidas de hoy',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton(
              onPressed: widget.onOpenHistory,
              child: const Text(
                'Ver historial',
                style: TextStyle(
                  color: AppTheme.primaryStart,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<DayMeals>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryStart,
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final day = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<int?>(
                  future: _dailyLimitFuture,
                  builder: (context, limitSnapshot) => _TodayCaloriesCard(
                    totalCalories: day.totalCalories,
                    dailyLimit: limitSnapshot.data,
                    limitError: limitSnapshot.hasError,
                    loadingLimit:
                        limitSnapshot.connectionState ==
                        ConnectionState.waiting,
                  ),
                ),
                const SizedBox(height: 16),
                DayMealsList(
                  day: day,
                  onOpen: (group) => showMealDetailSheet(
                    context,
                    group,
                    repository: _repository,
                  ),
                  onAdd: (type) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllFoodsScreen(mealType: type),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TodayCaloriesCard extends StatelessWidget {
  const _TodayCaloriesCard({
    required this.totalCalories,
    required this.dailyLimit,
    required this.limitError,
    required this.loadingLimit,
  });

  final int totalCalories;
  final int? dailyLimit;
  final bool limitError;
  final bool loadingLimit;

  @override
  Widget build(BuildContext context) {
    final formattedCalories = totalCalories.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    final int? difference = dailyLimit == null
        ? null
        : dailyLimit! - totalCalories;
    final goalMessage = loadingLimit
        ? 'Cargando tu objetivo diario...'
        : limitError
        ? 'No se pudo cargar tu objetivo diario.'
        : difference == null
        ? 'Completa tu perfil para calcular tu objetivo diario.'
        : difference > 0
        ? 'Te faltan ${_formatCalories(difference)} kcal para cumplir tu objetivo de hoy.'
        : difference < 0
        ? 'Te excediste por ${_formatCalories(difference.abs())} kcal de tu objetivo diario.'
        : '¡Has alcanzado tu objetivo diario!';

    return Container(
      key: const ValueKey('today-calories-card'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primaryStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.primaryStart,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calorías de hoy',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: AppTheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dailyLimit == null
                          ? 'Total consumido'
                          : 'Objetivo: ${_formatCalories(dailyLimit!)} kcal',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$formattedCalories kcal',
                    key: const ValueKey('today-calories-total'),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppTheme.primaryStart,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'consumidas',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            goalMessage,
            key: const ValueKey('today-calories-goal-message'),
            style: TextStyle(
              color: difference != null && difference < 0
                  ? const Color(0xFFB42318)
                  : AppTheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCalories(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]}.',
  );
}
