import 'package:dio/dio.dart';

import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

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
  });

  final Map<String, dynamic> profile;
  final List<PhysicalRecord> history;
  final Map<String, dynamic>? consumptionValidation;
  final Map<String, dynamic>? todayCalories;

  static const double _activityFactor = 1.2;
  static const double _maxCalorieAdjustment = 500;
  static const double _calorieAdjustmentRatio = 0.15;
  static const int _minSafeDailyCalories = 1200;

  String get firstName {
    final name = profile['name']?.toString().trim();
    if (name == null || name.isEmpty) {
      return 'Usuario';
    }

    return name.split(RegExp(r'\s+')).first;
  }

  String get goal {
    final value =
        consumptionValidation?['goal']?.toString() ??
        profile['goal']?.toString();
    if (value == null || value.trim().isEmpty) {
      return 'Sin meta';
    }

    return value.trim();
  }

  String get goalLabel {
    final normalized = goal.toLowerCase();
    if (normalized.contains('perder') ||
        normalized.contains('bajar') ||
        normalized.contains('lose')) {
      return 'Bajar peso';
    }

    if (normalized.contains('ganar') ||
        normalized.contains('subir') ||
        normalized.contains('gain')) {
      return 'Subir peso';
    }

    if (normalized.contains('mantener') || normalized.contains('maintain')) {
      return 'Mantener peso';
    }

    return goal;
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

  String get status {
    final value = consumptionValidation?['status']?.toString();
    if (value == null || value.trim().isEmpty) {
      return 'Sin datos';
    }

    return value.trim();
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
    final normalizedGoal = goal.toLowerCase();
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

  Future<ProgressData> fetchProgress() async {
    try {
      final profile = await _getMap(ApiRoutes.userProfile);
      final historyData = await _getList(ApiRoutes.userPhysicalHistory);
      final consumptionValidation = await _getOptionalMap(
        ApiRoutes.statsConsumptionValidation,
      );
      final todayCalories = await _getOptionalMap(ApiRoutes.statsTodayCalories);

      return ProgressData(
        profile: profile,
        history: historyData
            .whereType<Map>()
            .map((item) => PhysicalRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        consumptionValidation: consumptionValidation,
        todayCalories: todayCalories,
      );
    } on ProgressException {
      rethrow;
    } on DioException catch (error) {
      throw ProgressException(_fallbackMessage(error));
    } catch (_) {
      throw const ProgressException(
        'No se pudo cargar tu progreso. Inténtalo de nuevo.',
      );
    }
  }

  Future<Map<String, dynamic>> _getMap(String route) async {
    final data = await _getData(route);
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const ProgressException('El servidor respondió con datos inválidos.');
  }

  Future<List<dynamic>> _getList(String route) async {
    final data = await _getData(route);
    if (data is List) {
      return data;
    }

    return const [];
  }

  Future<Map<String, dynamic>?> _getOptionalMap(String route) async {
    try {
      final data = await _getData(route);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<dynamic> _getData(String route) async {
    final response = await _dio.get<Map<String, dynamic>>(route);
    final body = response.data;

    if (body != null && body['success'] == true) {
      return body['data'];
    }

    throw ProgressException(
      _extractFriendlyMessage(body) ?? 'No se pudo cargar la información.',
    );
  }

  String _fallbackMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión con el servidor tardó demasiado. Inténtalo de nuevo.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor. Verifica que el backend esté activo.';
      default:
        return 'No se pudo cargar tu progreso. Inténtalo de nuevo.';
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
