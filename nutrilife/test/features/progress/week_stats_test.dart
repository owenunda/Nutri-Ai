import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/week_stats.dart';

void main() {
  test('lee los 7 días, la meta y los promedios', () {
    final week = WeekStats.fromJson({
      'dailyLimit': 2120,
      'average': 1850,
      'daysOnTarget': 4,
      'days': [
        for (var i = 6; i <= 12; i++)
          {
            'date': '2026-10-${i.toString().padLeft(2, '0')}',
            'totalConsumed': i * 100,
          },
      ],
    });

    expect(week.days, hasLength(7));
    expect(week.days.first.date, DateTime(2026, 10, 6));
    expect(week.days.last.totalConsumed, 1200);
    expect(week.dailyLimit, 2120);
    expect(week.total, 6300);
  });

  test('sin meta deja dailyLimit en null', () {
    final week = WeekStats.fromJson({
      'dailyLimit': null,
      'average': 0,
      'daysOnTarget': 0,
      'days': [],
    });
    expect(week.dailyLimit, isNull);
  });
}
