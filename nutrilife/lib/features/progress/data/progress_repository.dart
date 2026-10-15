import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/local_date.dart';
import 'week_stats.dart';

class ProgressException implements Exception {
  const ProgressException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PhysicalRecord {
  const PhysicalRecord({
    required this.weight,
    required this.height,
    required this.recordDate,
  });

  final double? weight;
  final double? height;
  final DateTime? recordDate;

  factory PhysicalRecord.fromJson(Map<String, dynamic> json) {
    return PhysicalRecord(
      weight: _toDouble(json['weight']),
      height: _toDouble(json['height']),
      recordDate: _toDateTime(json['recordDate']),
    );
  }
}

class ProgressData {
  const ProgressData({
    required this.profile,
    required this.history,
    required this.consumptionValidation,
    required this.todayCalories,
    this.week,
  });

  final Map<String, dynamic> profile;
  final List<PhysicalRecord> history;
  final Map<String, dynamic>? consumptionValidation;
  final Map<String, dynamic>? todayCalories;
  final WeekStats? week;

  static const double _activityFactor = 1.2;
  static const double _maxCalorieAdjustment = 500;
  static const double _calorieAdjustmentRatio = 0.15;
  static const int _minSafeDailyCalories = 1200;

  String get firstName {
    final name = profile['name']?.toString().trim();
    if (name == null || name.isEmpty) {
      return currentL10n.commonUser;
    }

    return name.split(RegExp(r'\s+')).first;
  }

  /// Meta tal como la guarda el backend ('Perder peso', 'Mantener peso'...).
  /// Es `null` si el perfil no tiene meta.
  String? get goal {
    final value =
        consumptionValidation?['goal']?.toString() ??
        profile['goal']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  /// Meta para mostrar. Los valores del backend se traducen; uno desconocido
  /// se muestra tal cual.
  String get goalLabel {
    final l10n = currentL10n;
    final value = goal;
    if (value == null) {
      return l10n.progressGoalNone;
    }

    final normalized = value.toLowerCase();
    if (normalized.contains('perder') ||
        normalized.contains('bajar') ||
        normalized.contains('lose')) {
      return l10n.progressGoalLose;
    }

    if (normalized.contains('ganar') ||
        normalized.contains('subir') ||
        normalized.contains('gain')) {
      return l10n.progressGoalGain;
    }

    if (normalized.contains('mantener') || normalized.contains('maintain')) {
      return l10n.progressGoalMaintain;
    }

    return value;
  }

  double? get currentWeight {
    return _toDouble(profile['weight']) ??
        (history.isNotEmpty ? history.first.weight : null);
  }

  double? get currentHeight {
    return _toDouble(profile['height']) ??
        (history.isNotEmpty ? history.first.height : null);
  }

  int? get dailyLimit {
    final backendLimit = _toInt(consumptionValidation?['dailyLimit']);
    if (backendLimit != null) {
      return _safeDailyLimit(backendLimit);
    }

    final calculatedLimit = _calculateDailyLimitFromProfile();
    if (calculatedLimit == null) {
      return null;
    }

    return _safeDailyLimit(calculatedLimit);
  }

  int get totalConsumed {
    return _toInt(consumptionValidation?['totalConsumed']) ??
        _toInt(todayCalories?['totalConsumed']) ??
        0;
  }

  int? get remaining {
    final limit = dailyLimit;
    if (limit == null) {
      return null;
    }

    final value = limit - totalConsumed;
    return value < 0 ? 0 : value;
  }

  /// Estado que manda el backend ('OK', 'EXCEDIDO'). `null` si no hay datos.
  String? get status {
    final value = consumptionValidation?['status']?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  bool get isExceeded => status?.toUpperCase() == 'EXCEDIDO';

  /// Estado para mostrar: el código 'EXCEDIDO' se traduce, 'OK' queda igual.
  String get statusLabel {
    final l10n = currentL10n;
    final value = status;
    if (value == null) {
      return l10n.progressStatusNoData;
    }

    return isExceeded ? l10n.progressStatusExceeded : value;
  }

  List<PhysicalRecord> get orderedHistory {
    final copy = [...history];
    copy.sort((a, b) {
      final firstDate = a.recordDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate = b.recordDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return firstDate.compareTo(secondDate);
    });
    return copy;
  }

  double? get latestWeightChange {
    if (history.length < 2) {
      return null;
    }

    final current = history[0].weight;
    final previous = history[1].weight;
    if (current == null || previous == null) {
      return null;
    }

    final currentDate = history[0].recordDate;
    final previousDate = history[1].recordDate;
    if (_isSameDay(currentDate, previousDate)) {
      return null;
    }

    final change = current - previous;
    if (change.abs() > 15) {
      return null;
    }

    return change;
  }

  double get calorieProgress {
    final limit = dailyLimit;
    if (limit == null || limit <= 0) {
      return 0;
    }

    final progress = totalConsumed / limit;
    return progress.clamp(0, 1).toDouble();
  }

  int? _calculateDailyLimitFromProfile() {
    final age = _toInt(profile['age']);
    final weight = currentWeight;
    final height = currentHeight;

    if (age == null || weight == null || height == null) {
      return null;
    }

    final heightInCentimeters = height <= 3 ? height * 100 : height;
    final bmr = (10 * weight) + (6.25 * heightInCentimeters) - (5 * age) - 80;
    final maintenanceCalories = bmr * _activityFactor;
    final normalizedGoal = (goal ?? '').toLowerCase();
    var dailyCalories = maintenanceCalories;

    if (normalizedGoal.contains('perder') ||
        normalizedGoal.contains('bajar') ||
        normalizedGoal.contains('lose')) {
      dailyCalories -= _moderateAdjustment(maintenanceCalories);
    } else if (normalizedGoal.contains('ganar') ||
        normalizedGoal.contains('subir') ||
        normalizedGoal.contains('gain')) {
      dailyCalories += _moderateAdjustment(maintenanceCalories);
    }

    return dailyCalories.round();
  }

  int _safeDailyLimit(int value) {
    return value < _minSafeDailyCalories ? _minSafeDailyCalories : value;
  }

  double _moderateAdjustment(double maintenanceCalories) {
    final adjustment = maintenanceCalories * _calorieAdjustmentRatio;
    return adjustment > _maxCalorieAdjustment
        ? _maxCalorieAdjustment
        : adjustment;
  }
}

class ProgressRepository {
  ProgressRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<int?> fetchDailyLimit({DateTime? now}) async {
    try {
      final date = localDateString(now);
      final profile = await _getMap(ApiRoutes.userProfile);
      final historyData = await _getList(ApiRoutes.userPhysicalHistory);
      final consumptionValidation = await _getOptionalMap(
        ApiRoutes.statsConsumptionValidation,
        query: {'date': date},
      );
      return ProgressData(
        profile: profile,
        history: historyData
            .whereType<Map>()
            .map(
              (item) => PhysicalRecord.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        consumptionValidation: consumptionValidation,
        todayCalories: null,
      ).dailyLimit;
    } on ProgressException {
      rethrow;
    } on DioException catch (error) {
      throw ProgressException(_fallbackMessage(error));
    } catch (_) {
      throw ProgressException(currentL10n.progressErrorLoadDailyGoal);
    }
  }

  Future<ProgressData> fetchProgress({DateTime? now}) async {
    try {
      final date = localDateString(now);
      final profile = await _getMap(ApiRoutes.userProfile);
      final historyData = await _getList(ApiRoutes.userPhysicalHistory);
      final consumptionValidation = await _getOptionalMap(
        ApiRoutes.statsConsumptionValidation,
        query: {'date': date},
      );
      final todayCalories = await _getOptionalMap(
        ApiRoutes.statsTodayCalories,
        query: {'date': date},
      );
      final weekData = await _getOptionalMap(
        ApiRoutes.statsWeek,
        query: {'end': date},
      );

      return ProgressData(
        profile: profile,
        history: historyData
            .whereType<Map>()
            .map((item) => PhysicalRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        consumptionValidation: consumptionValidation,
        todayCalories: todayCalories,
        week: weekData == null ? null : WeekStats.fromJson(weekData),
      );
    } on ProgressException {
      rethrow;
    } on DioException catch (error) {
      throw ProgressException(_fallbackMessage(error));
    } catch (_) {
      throw ProgressException(currentL10n.progressErrorLoad);
    }
  }

  Future<void> addWeight({required double weight, required double height}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiRoutes.userPhysical,
        data: {'weight': weight, 'height': height},
      );
    } on DioException catch (error) {
      throw ProgressException(
        error.response?.data?['message']?.toString() ?? currentL10n.progressErrorSaveWeight,
      );
    }
  }

  Future<Map<String, dynamic>> _getMap(String route) async {
    final data = await _getData(route);
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw ProgressException(currentL10n.progressErrorInvalidData);
  }

  Future<List<dynamic>> _getList(String route) async {
    final data = await _getData(route);
    if (data is List) {
      return data;
    }

    return const [];
  }

  Future<Map<String, dynamic>?> _getOptionalMap(
    String route, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final data = await _getData(route, query: query);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<dynamic> _getData(String route, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      route,
      queryParameters: query,
    );
    final body = response.data;

    if (body != null && body['success'] == true) {
      return body['data'];
    }

    throw ProgressException(
      _extractFriendlyMessage(body) ?? currentL10n.progressErrorLoadInfo,
    );
  }

  String _fallbackMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return currentL10n.commonErrorTimeout;
      case DioExceptionType.connectionError:
        return currentL10n.commonErrorConnection;
      default:
        return currentL10n.progressErrorLoad;
    }
  }

  String? _extractFriendlyMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }
}

double? _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }

  return null;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'))?.round();
  }

  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

bool _isSameDay(DateTime? firstDate, DateTime? secondDate) {
  if (firstDate == null || secondDate == null) {
    return false;
  }

  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}
