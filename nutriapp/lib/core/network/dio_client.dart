import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_base_url.dart';
import '../navigation/navigator_key.dart';
import '../services/session_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class DioClient {
  DioClient._();

  static String? authToken;
  static bool _isRedirectingToLogin = false;

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiBaseUrl.value,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _redirectToLogin();
          }
          return handler.next(error);
        },
      ),
    );

  static Future<void> _redirectToLogin() async {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    await SessionService.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    _isRedirectingToLogin = false;
  }
}

