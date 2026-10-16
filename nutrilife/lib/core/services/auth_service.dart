import 'package:dio/dio.dart';
import '../l10n/l10n.dart';
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
          'needsProfileSetup':
              responseData['data']['needsProfileSetup'] == true,
          'message': responseData['message'] ?? currentL10n.authLoginSuccess,
        };
      } else {
        final errorMessage = responseData?['message'] ?? currentL10n.authErrorLogin;
        return {
          'success': false,
          'message': errorMessage,
          'error': responseData?['error'],
        };
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMessage = currentL10n.authErrorLogin;

      if (responseData is Map<String, dynamic> && responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = currentL10n.commonErrorTimeout;
            break;
          case DioExceptionType.connectionError:
            errorMessage = currentL10n.commonErrorConnection;
            break;
          default:
            errorMessage = currentL10n.authErrorNetwork(e.message ?? '');
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
        'message': currentL10n.authErrorUnexpected(e.toString()),
      };
    }
  }
}
