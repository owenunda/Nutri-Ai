class DayCalories {
  final DateTime date;
  final int totalConsumed;

  const DayCalories({required this.date, required this.totalConsumed});
}

class WeekStats {
  final int? dailyLimit;
  final List<DayCalories> days;
  final int average;
  final int daysOnTarget;

  const WeekStats({
    required this.dailyLimit,
    required this.days,
    required this.average,
    required this.daysOnTarget,
  });

  int get total => days.fold(0, (sum, d) => sum + d.totalConsumed);

  bool get hasTargetHistory => dailyLimit != null && days.isNotEmpty;

  int currentGoalStreak({DateTime? now}) {
    final limit = dailyLimit;
    if (limit == null || limit <= 0 || days.isEmpty) return 0;

    final today = _dateOnly(now ?? DateTime.now());
    final todayCalories = _caloriesByDate[_dateKey(today)];
    if (todayCalories != null && todayCalories > limit) return 0;

    final dailyGoals = _goalDays(today);
    var index = dailyGoals.length - 1;
    if (!dailyGoals[index] && index > 0) index--;

    var streak = 0;
    while (index >= 0 && dailyGoals[index]) {
      streak++;
      index--;
    }
    return streak;
  }

  int bestGoalStreak({DateTime? now}) {
    final limit = dailyLimit;
    if (limit == null || limit <= 0 || days.isEmpty) return 0;

    var best = 0;
    var current = 0;
    for (final completed in _goalDays(_dateOnly(now ?? DateTime.now()))) {
      current = completed ? current + 1 : 0;
      if (current > best) best = current;
    }
    return best;
  }

  List<bool> _goalDays(DateTime today) {
    final caloriesByDate = _caloriesByDate;
    final limit = dailyLimit!;
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final calories = caloriesByDate[_dateKey(date)] ?? 0;
      return calories > 0 && calories <= limit;
    }, growable: false);
  }

  Map<String, int> get _caloriesByDate => {
    for (final day in days) _dateKey(day.date): day.totalConsumed,
  };

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  factory WeekStats.fromJson(Map map) => WeekStats(
        dailyLimit: (map['dailyLimit'] as num?)?.round(),
        average: (map['average'] as num?)?.round() ?? 0,
        daysOnTarget: (map['daysOnTarget'] as num?)?.round() ?? 0,
        days: (map['days'] as List? ?? const [])
            .whereType<Map>()
            .map((d) {
              final parts = (d['date'] as String).split('-').map(int.parse).toList();
              return DayCalories(
                date: DateTime(parts[0], parts[1], parts[2]),
                totalConsumed: (d['totalConsumed'] as num?)?.round() ?? 0,
              );
            })
            .toList(),
      );
}
