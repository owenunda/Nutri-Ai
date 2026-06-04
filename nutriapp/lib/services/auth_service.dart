import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  // Base URL del backend.
  // En modo debug usamos localhost y `adb reverse` para pruebas con dispositivo físico:
  // - Debug: http://127.0.0.1:3000/api/v1  (usa `adb reverse tcp:3000 tcp:3000`)
  // - Release: mantiene la URL real (ajusta antes de producción)
  static String get baseUrl {
    if (kDebugMode) return 'http://127.0.0.1:3000/api/v1';
    return 'http://192.168.1.8:3000/api/v1';
  }

  /// Realiza el login con email y password
  ///
  /// Retorna un mapa con:
  /// - success: bool
  /// - token: string (si success=true)
  /// - user: Map<String, dynamic> (si success=true)
  /// - message: string (mensaje de error si success=false)
  ///
  /// Lanza Exception si hay error de red o parsing
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Parsear la respuesta
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Login exitoso
        return {
          'success': true,
          'token': responseData['data']['token'],
          'user': responseData['data']['user'],
          'message': responseData['message'] ?? 'Login successful',
        };
      } else {
        // Error del backend
        final errorMessage = responseData['message'] ?? 'Login failed';
        return {
          'success': false,
          'message': errorMessage,
          'error': responseData['error'],
        };
      }
    } on http.ClientException catch (e) {
      // Error de red
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      // Otros errores
      throw Exception('Error: $e');
    }
  }
}
