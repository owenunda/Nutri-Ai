import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/local_date.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/data/models/day_meals.dart';
import '../../../meals/presentation/widgets/day_meals_list.dart';
import '../../../meals/presentation/widgets/meal_detail_sheet.dart';
import '../../../nutrition/presentation/screens/all_foods_screen.dart';

/// "Comidas de hoy" con lo que el usuario registró de verdad.
class TodayMealsSection extends StatefulWidget {
  final MealRepository? repository;
  final DateTime Function()? clock;
  final VoidCallback? onOpenHistory;

  const TodayMealsSection({super.key, this.repository, this.clock, this.onOpenHistory});

  @override
  State<TodayMealsSection> createState() => _TodayMealsSectionState();
}

class _TodayMealsSectionState extends State<TodayMealsSection> {
  late final MealRepository _repository = widget.repository ?? MealRepository();
  late Future<DayMeals> _future;

  String get _today => localDateString((widget.clock ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _future = _repository.getDay(_today);
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
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryStart)),
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
                  TextButton(onPressed: _reload, child: const Text('Reintentar')),
                ],
              );
            }
            return DayMealsList(
              day: snapshot.data!,
              onOpen: (group) => showMealDetailSheet(context, group, repository: _repository),
              onAdd: (type) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AllFoodsScreen(mealType: type)),
              ),
            );
          },
        ),
      ],
    );
  }
}
