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
