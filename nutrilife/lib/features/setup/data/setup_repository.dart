import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

class SetupException implements Exception {
  const SetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SetupRepository {
  SetupRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<void> updateProfile({
    int? age,
    double? weight,
    double? height,
    String? goal,
  }) async {
    final body = <String, dynamic>{};

    if (age != null) {
      body['age'] = age;
    }

    if (weight != null) {
      body['weight'] = weight;
    }

    if (height != null) {
      body['height'] = height;
    }

    if (goal != null && goal.trim().isNotEmpty) {
      body['goal'] = goal.trim();
    }

    if (body.isEmpty) {
      throw SetupException(currentL10n.setupErrorNothingToSave);
    }

    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiRoutes.userProfile,
        data: body,
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        return;
      }

      throw SetupException(
        _extractFriendlyMessage(data) ?? currentL10n.setupErrorSave,
      );
    } on DioException catch (error) {
      throw SetupException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error),
      );
    } on SetupException {
      rethrow;
    } catch (_) {
      throw SetupException(currentL10n.setupErrorSave);
    }
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
        return currentL10n.setupErrorSave;
    }
  }

  String? _extractFriendlyMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final details = data['error'];
    if (details is Map<String, dynamic>) {
      final errors = details['details'];
      if (errors is List && errors.isNotEmpty) {
        final messages = errors
            .whereType<Map>()
            .map((item) => item['message'])
            .whereType<String>()
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }
}
