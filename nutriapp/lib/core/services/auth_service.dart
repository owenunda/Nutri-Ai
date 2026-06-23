import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_routes.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        ApiRoutes.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data;

      if (responseData != null && responseData['success'] == true) {
        return {
          'success': true,
          'token': responseData['data']['token'],
          'user': responseData['data']['user'],
          'message': responseData['message'] ?? 'Login successful',
        };
      } else {
        final errorMessage = responseData?['message'] ?? 'Login failed';
        return {
          'success': false,
          'message': errorMessage,
          'error': responseData?['error'],
        };
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMessage = 'No se pudo iniciar sesión. Inténtalo de nuevo.';

      if (responseData is Map<String, dynamic> && responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'La conexión con el servidor tardó demasiado. Inténtalo de nuevo.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión o si el servidor está activo.';
            break;
          default:
            errorMessage = 'Error de red: ${e.message}';
        }
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': responseData?['error'] ?? e.error,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
