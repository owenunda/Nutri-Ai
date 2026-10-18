import 'package:flutter/material.dart';
import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/local_date.dart';
import '../../data/meal_repository.dart';
import '../../data/models/day_meals.dart';
import '../widgets/day_meals_list.dart';
import '../widgets/meal_detail_sheet.dart';

class MealHistoryScreen extends StatefulWidget {
  final MealRepository? repository;
  final DateTime Function()? clock;

  const MealHistoryScreen({super.key, this.repository, this.clock});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  late final MealRepository _repository = widget.repository ?? MealRepository();
  late final DateTime _today = _dateOnly((widget.clock ?? DateTime.now)());
  late DateTime _day = _today;
  late Future<DayMeals> _future = _repository.getDay(localDateString(_day));

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
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
      _future = _repository.getDay(localDateString(_day));
    });
  }

  void _move(int days) {
    _day = DateTime(_day.year, _day.month, _day.day + days);
    _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(_today.year - 5),
      lastDate: _today,
      helpText: context.l10n.mealsPickDate,
    );
    if (picked == null || _dateOnly(picked) == _day) return;
    _day = _dateOnly(picked);
    _reload();
  }

  String _title(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    // Diferencia en fechas de calendario (en UTC) para no depender del horario de verano.
    final diff = DateTime.utc(_today.year, _today.month, _today.day)
        .difference(DateTime.utc(_day.year, _day.month, _day.day))
        .inDays;
    if (diff == 0) return l10n.mealsToday;
    if (diff == 1) return l10n.mealsYesterday;
    return l10n.mealsDateLabel(
      shortWeekday(_day, languageCode),
      _day.day,
      shortMonth(_day, languageCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isToday = _day == _today;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
        title: Text(
          l10n.mealsHistoryTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            tooltip: l10n.mealsPickDate,
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24, 8, 24, 32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.mealsPreviousDay,
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _title(context),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF747779)),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.mealsNextDay,
                onPressed: isToday ? null : () => _move(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<DayMeals>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryStart)),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                    TextButton(onPressed: _reload, child: Text(l10n.commonRetry)),
                  ],
                );
              }
              final day = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.totalCalories} kcal',
                    style: const TextStyle(
                      color: AppTheme.primaryStart,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DayMealsList(
                    day: day,
                    onOpen: (group) => showMealDetailSheet(context, group, repository: _repository),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
