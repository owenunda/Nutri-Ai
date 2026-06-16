import 'package:dio/dio.dart';

import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.authRegister,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        return;
      }

      throw AuthException(
        _extractFriendlyMessage(data) ?? 'No se pudo completar el registro.',
      );
    } on DioException catch (error) {
      throw AuthException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error),
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'No se pudo completar el registro. Inténtalo de nuevo.',
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
        return 'No se pudo completar el registro. Inténtalo de nuevo.';
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
      'Name is required': 'El nombre es obligatorio.',
      'Email is required': 'El correo electrónico es obligatorio.',
      'Email format is invalid': 'El formato del correo electrónico no es válido.',
      'Password is required': 'La contraseña es obligatoria.',
      'Password must be at least 6 characters':
          'La contraseña debe tener al menos 6 caracteres.',
      'Email is already registered': 'Ese correo ya está registrado.',
      'Default role or plan is not configured':
          'Falta configurar el rol o plan por defecto.',
      'Invalid credentials': 'Correo o contraseña inválidos.',
      'JWT secret is not configured':
          'Falta configurar el secreto JWT en el backend.',
    };

    return translations[message] ?? message;
  }
}
