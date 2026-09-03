import 'package:dio/dio.dart';

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
      throw const SetupException('No hay datos para guardar.');
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
        _extractFriendlyMessage(data) ?? 'No se pudo guardar la información.',
      );
    } on DioException catch (error) {
      throw SetupException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error),
      );
    } on SetupException {
      rethrow;
    } catch (_) {
      throw const SetupException(
        'No se pudo guardar la información. Inténtalo de nuevo.',
      );
    }
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
        return 'No se pudo guardar la información. Inténtalo de nuevo.';
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
            .map(_translateMessage)
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return _translateMessage(message);
    }

    return null;
  }

  String _translateMessage(String message) {
    const translations = {
      'Validation error': 'Revisa los campos marcados e inténtalo de nuevo.',
      'At least one field must be provided: age, weight, height or goal':
          'Debes enviar al menos un dato para actualizar.',
      'Age must be an integer between 16 and 120':
          'La edad debe estar entre 16 y 120 años.',
      'Weight must be a number greater than 0':
          'El peso debe ser un número válido.',
      'Height must be a number greater than 0':
          'La altura debe ser un número válido.',
      'Goal must be a non-empty string': 'Selecciona una meta para continuar.',
      'Goal must contain a single value': 'Selecciona una sola meta.',
      'User not found': 'No se encontró el usuario autenticado.',
    };

    return translations[message] ?? message;
  }
}
