import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.sex,
    required this.plan,
    required this.createdAt,
    required this.hasPassword,
    this.proUntil,
  });

  final String name;
  final String email;
  final int? age;
  final double? weight;
  final double? height;
  final String? goal;
  final String? sex;
  final String? plan;
  final DateTime? createdAt;

  /// Fin del PRO regalado, en hora local. Null con PRO = sin vencimiento.
  final DateTime? proUntil;

  bool get isPro => plan?.toUpperCase() == 'PRO';

  /// false si la cuenta solo entra con Google.
  final bool hasPassword;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString().trim() ?? currentL10n.commonUser,
      email: json['email']?.toString().trim() ?? '',
      age: _toInt(json['age']),
      weight: _toDouble(json['weight']),
      height: _toDouble(json['height']),
      goal: json['goal']?.toString().trim(),
      sex: null,
      plan: json['plan']?.toString().trim(),
      createdAt: _toDateTime(json['createdAt']),
      hasPassword: json['hasPassword'] != false,
      proUntil: _toDateTime(json['proUntil'])?.toLocal(),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? sex,
    String? plan,
    DateTime? createdAt,
    bool? hasPassword,
    DateTime? proUntil,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      sex: sex ?? this.sex,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      hasPassword: hasPassword ?? this.hasPassword,
      proUntil: proUntil ?? this.proUntil,
    );
  }

  String membershipText(AppLocalizations l10n) {
    final currentPlan = plan;
    final year = createdAt?.year;

    if (currentPlan == null || currentPlan.isEmpty) {
      return year == null
          ? l10n.profileMemberDefault
          : l10n.profileMemberSince('$year');
    }

    return year == null
        ? l10n.profileMemberPlan(currentPlan)
        : l10n.profileMemberPlanSince(currentPlan, '$year');
  }
}

class ProfileRepository {
  ProfileRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.userProfile,
      );
      final body = response.data;
      final data = body?['data'];

      if (body != null && body['success'] == true && data is Map) {
        final profile = UserProfile.fromJson(Map<String, dynamic>.from(data));
        final localSex = await getLocalSex(profile.email);
        return profile.copyWith(sex: localSex);
      }

      throw ProfileException(
        _extractFriendlyMessage(body) ?? currentL10n.profileLoadError,
      );
    } on DioException catch (error) {
      throw ProfileException(
        _extractFriendlyMessage(error.response?.data) ?? _fallbackMessage(error),
      );
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw ProfileException(currentL10n.profileLoadErrorRetry);
    }
  }

  Future<void> updateProfile({
    required int age,
    required double height,
    required String goal,
    required String sex,
    required String email,
    double? weight,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiRoutes.userProfile,
        data: {
          'age': age,
          'height': height,
          'goal': goal,
          'weight': ?weight,
        },
      );

      final body = response.data;
      if (body != null && body['success'] == true) {
        await saveLocalSex(email, sex);
        return;
      }

      throw ProfileException(
        _extractFriendlyMessage(body) ?? currentL10n.profileUpdateError,
      );
    } on DioException catch (error) {
      throw ProfileException(
        _extractFriendlyMessage(error.response?.data) ?? _fallbackMessage(error),
      );
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw ProfileException(currentL10n.profileUpdateErrorRetry);
    }
  }

  // Borra la cuenta en el backend y lo que la app guardó de ella en el
  // dispositivo. La sesión la limpia quien llama, igual que al cerrar sesión.
  // Se confirma con la contraseña o, si la cuenta no tiene, con Google.
  Future<void> deleteAccount({
    String? password,
    String? googleIdToken,
    required String email,
  }) async {
    assert(
      (password == null) != (googleIdToken == null),
      'Pasa la contraseña o el idToken de Google, no ambos',
    );

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiRoutes.userAccount,
        data: password != null
            ? {'password': password}
            : {'googleIdToken': googleIdToken},
      );

      final body = response.data;
      if (body != null && body['success'] == true) {
        if (email.trim().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_sexKey(email));
        }
        return;
      }

      throw ProfileException(
        _extractFriendlyMessage(body) ?? currentL10n.profileDeleteError,
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final errorInfo = data is Map ? data['error'] : null;
      final code = errorInfo is Map ? errorInfo['code'] : null;
      if (code == 'INVALID_PASSWORD') {
        throw ProfileException(currentL10n.profileDeleteWrongPassword);
      }
      if (code == 'GOOGLE_ACCOUNT_MISMATCH') {
        throw ProfileException(currentL10n.profileDeleteGoogleMismatch);
      }
      if (code == 'INVALID_GOOGLE_TOKEN') {
        throw ProfileException(currentL10n.profileDeleteGoogleFailed);
      }
      throw ProfileException(
        _extractFriendlyMessage(data) ?? _fallbackMessage(error),
      );
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw ProfileException(currentL10n.profileDeleteErrorRetry);
    }
  }

  Future<String?> getLocalSex(String email) async {
    if (email.trim().isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sexKey(email));
  }

  Future<void> saveLocalSex(String email, String sex) async {
    if (email.trim().isEmpty || sex.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sexKey(email), sex.trim());
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
        return currentL10n.profileLoadErrorRetry;
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

String _sexKey(String email) => 'profile_sex_${email.trim().toLowerCase()}';

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
    return int.tryParse(value);
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
