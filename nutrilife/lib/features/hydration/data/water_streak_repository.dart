import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/local_date.dart';

class WaterStreakSnapshot {
  const WaterStreakSnapshot({
    required this.date,
    required this.glassesToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastSevenDays,
    required this.totalGlasses,
  });

  final String date;
  final int glassesToday;
  final int currentStreak;
  final int bestStreak;
  final List<int> lastSevenDays;
  final int totalGlasses;

  bool get goalCompleted => glassesToday >= WaterStreakRepository.dailyGoal;
}

class WaterStreakState extends ChangeNotifier {
  WaterStreakState._();

  static final WaterStreakState instance = WaterStreakState._();

  int _revision = 0;
  int get revision => _revision;

  void bump() {
    _revision++;
    notifyListeners();
  }
}

class WaterStreakRepository {
  WaterStreakRepository({required String accountId})
    : _storageKey =
          'water_streak_v1_${Uri.encodeComponent(accountId.trim().toLowerCase())}';

  static const int dailyGoal = 4;
  static const int _previousDailyGoal = 5;

  final String _storageKey;

  Future<WaterStreakSnapshot> load({DateTime? now}) async {
    final history = await _readHistory();
    return _snapshot(history, localDateString(now));
  }

  Future<WaterStreakSnapshot> addGlass({DateTime? now}) async {
    final history = await _readHistory();
    final today = localDateString(now);
    final currentCount = history[today] ?? 0;
    if (currentCount < dailyGoal) {
      history[today] = currentCount + 1;
      await _writeHistory(history);
      WaterStreakState.instance.bump();
    }
    return _snapshot(history, today);
  }

  Future<WaterStreakSnapshot> undoGlass({DateTime? now}) async {
    final history = await _readHistory();
    final today = localDateString(now);
    final currentCount = history[today] ?? 0;
    if (currentCount > 0) {
      if (currentCount == 1) {
        history.remove(today);
      } else {
        history[today] = currentCount - 1;
      }
      await _writeHistory(history);
      WaterStreakState.instance.bump();
    }
    return _snapshot(history, today);
  }

  Future<Map<String, int>> _readHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final storedHistory = preferences.getString(_storageKey);
    if (storedHistory == null) {
      return {};
    }

    final decoded = jsonDecode(storedHistory);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El historial de hidratación no es válido.');
    }

    final history = <String, int>{};
    var migratedHistory = false;
    for (final entry in decoded.entries) {
      final parsedDate = DateTime.tryParse(entry.key);
      final count = entry.value;
      if (parsedDate == null ||
          localDateString(parsedDate) != entry.key ||
          count is! int ||
          count < 1 ||
          count > _previousDailyGoal) {
        throw const FormatException(
          'El historial de hidratación contiene datos no válidos.',
        );
      }
      if (count > dailyGoal) {
        history[entry.key] = dailyGoal;
        migratedHistory = true;
      } else {
        history[entry.key] = count;
      }
    }
    if (migratedHistory) {
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode(history),
      );
      if (!saved) {
        throw StateError('No se pudo actualizar el historial de hidratación.');
      }
    }
    return history;
  }

  Future<void> _writeHistory(Map<String, int> history) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(history),
    );
    if (!saved) {
      throw StateError('No se pudo guardar el historial de hidratación.');
    }
  }

  WaterStreakSnapshot _snapshot(Map<String, int> history, String today) {
    final parsedToday = DateTime.parse(today);
    final lastSevenDays = List<int>.generate(7, (index) {
      final date = DateTime(
        parsedToday.year,
        parsedToday.month,
        parsedToday.day - (6 - index),
      );
      return history[localDateString(date)] ?? 0;
    }, growable: false);
    return WaterStreakSnapshot(
      date: today,
      glassesToday: history[today] ?? 0,
      currentStreak: _currentStreak(history, today),
      bestStreak: _bestStreak(history),
      lastSevenDays: lastSevenDays,
      totalGlasses: history.values.fold(0, (sum, value) => sum + value),
    );
  }

  int _currentStreak(Map<String, int> history, String today) {
    var anchor = today;
    if ((history[anchor] ?? 0) < dailyGoal) {
      anchor = _previousDate(anchor);
      if ((history[anchor] ?? 0) < dailyGoal) {
        return 0;
      }
    }

    var streak = 0;
    var date = anchor;
    while ((history[date] ?? 0) >= dailyGoal) {
      streak++;
      date = _previousDate(date);
    }
    return streak;
  }

  int _bestStreak(Map<String, int> history) {
    final completedDates =
        history.entries
            .where((entry) => entry.value >= dailyGoal)
            .map((entry) => entry.key)
            .toList()
          ..sort();

    var best = 0;
    var current = 0;
    String? previous;
    for (final date in completedDates) {
      current = previous != null && date == _nextDate(previous)
          ? current + 1
          : 1;
      if (current > best) {
        best = current;
      }
      previous = date;
    }
    return best;
  }

  String _previousDate(String date) {
    final parsed = DateTime.parse(date);
    return localDateString(DateTime(parsed.year, parsed.month, parsed.day - 1));
  }

  String _nextDate(String date) {
    final parsed = DateTime.parse(date);
    return localDateString(DateTime(parsed.year, parsed.month, parsed.day + 1));
  }
}
