import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
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
  WaterStreakRepository({required String accountId, Dio? dio})
    : _legacyKey =
          'water_streak_v1_${Uri.encodeComponent(accountId.trim().toLowerCase())}',
      _dio = dio ?? DioClient.instance;

  static const int dailyGoal = 4;
  static const int _legacyMaxGlasses = 5;
  static const int _importMaxEntries = 1000;

  /// Clave del historial que vivía solo en el teléfono, antes del backend.
  final String _legacyKey;
  final Dio _dio;

  Future<WaterStreakSnapshot> load({DateTime? now}) async {
    final today = localDateString(now);
    await _importLegacyHistory(today);
    return _snapshot(await _fetchHistory(), today);
  }

  Future<WaterStreakSnapshot> addGlass({DateTime? now}) =>
      _changeGlasses(ApiRoutes.hydrationGlass, now);

  Future<WaterStreakSnapshot> undoGlass({DateTime? now}) =>
      _changeGlasses(ApiRoutes.hydrationGlassUndo, now);

  Future<WaterStreakSnapshot> _changeGlasses(String route, DateTime? now) async {
    final today = localDateString(now);
    final history = await _fetchHistory();
    final int glasses;
    try {
      final response = await _dio.post<Map<String, dynamic>>(route, data: {'date': today});
      glasses = ((response.data?['data'] as Map?)?['glasses'] as num?)?.toInt() ?? 0;
    } on DioException {
      throw Exception(currentL10n.hydrationErrorSave);
    }
    if (glasses > 0) {
      history[today] = glasses;
    } else {
      history.remove(today);
    }
    WaterStreakState.instance.bump();
    return _snapshot(history, today);
  }

  Future<Map<String, int>> _fetchHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiRoutes.hydration);
      final raw = (response.data?['data'] as Map?)?['history'];
      if (raw is! Map) throw Exception(currentL10n.hydrationErrorInvalidHistory);
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } on DioException {
      throw Exception(currentL10n.hydrationErrorLoad);
    }
  }

  /// Sube una sola vez lo que estaba guardado en el teléfono. Si el servidor
  /// no responde, se deja para el próximo intento. Las entradas raras, las
  /// fechas futuras (el servidor rechaza todo el import si alguna pasa de
  /// mañana) y las que sobran de las 1.000 más recientes se descartan. Si el
  /// servidor rechaza el historial con un 4xx (salvo 408 y 429), ya no sirve y
  /// también se borra.
  Future<void> _importLegacyHistory(String today) async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_legacyKey);
    if (stored == null) return;

    final history = <String, int>{};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final day = entry.key;
          final count = entry.value;
          final parsed = day is String ? DateTime.tryParse(day) : null;
          if (parsed == null || localDateString(parsed) != day) continue;
          if (count is! int || count < 1 || count > _legacyMaxGlasses) continue;
          history[day as String] = count;
        }
      }
    } on FormatException {
      // JSON roto: no hay nada que rescatar.
    }

    final latest = _nextDate(today);
    history.removeWhere((day, _) => day.compareTo(latest) > 0);
    if (history.length > _importMaxEntries) {
      final recent = history.keys.toList()..sort();
      for (final day in recent.take(history.length - _importMaxEntries)) {
        history.remove(day);
      }
    }

    if (history.isNotEmpty) {
      try {
        await _dio.post<void>(ApiRoutes.hydrationImport, data: {'history': history});
      } on DioException catch (error) {
        if (!_isPermanentRejection(error.response?.statusCode)) {
          throw Exception(currentL10n.hydrationErrorLoad);
        }
      }
    }
    await preferences.remove(_legacyKey);
  }

  bool _isPermanentRejection(int? status) =>
      status != null && status >= 400 && status < 500 && status != 408 && status != 429;

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
