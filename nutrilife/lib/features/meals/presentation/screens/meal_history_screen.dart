import 'package:flutter/material.dart';
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
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

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

  String get _title {
    final diff = _today.difference(_day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${_weekdays[_day.weekday - 1]} ${_day.day} ${_months[_day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _day == _today;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
        title: const Text(
          'Historial de comidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Día anterior',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Día siguiente',
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
                    TextButton(onPressed: _reload, child: const Text('Reintentar')),
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
