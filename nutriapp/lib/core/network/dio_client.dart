import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_base_url.dart';
import '../navigation/navigator_key.dart';
import '../services/session_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'rate_limit_state.dart';

class DioClient {
  DioClient._();

  static String? authToken;
  static bool _isRedirectingToLogin = false;
  static final RateLimitState rateLimit = RateLimitState();

  static final Dio instance =
      Dio(
          BaseOptions(
            baseUrl: ApiBaseUrl.value,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            headers: const {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (authToken != null) {
                options.headers['Authorization'] = 'Bearer $authToken';
              }
              return handler.next(options);
            },
            onResponse: (response, handler) {
              _parseRateLimitHeaders(response.headers);
              return handler.next(response);
            },
            onError: (error, handler) {
              _parseRateLimitHeaders(error.response?.headers);
              if (error.response?.statusCode == 429) {
                final retryAfter =
                    int.tryParse(
                      error.response?.headers.value('Retry-After') ?? '',
                    ) ??
                    rateLimit.resetSeconds ??
                    60;
                final limit =
                    int.tryParse(
                      error.response?.headers.value('X-RateLimit-Limit') ?? '',
                    ) ??
                    rateLimit.limit ??
                    0;
                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: error.type,
                    error: RateLimitException(
                      retryAfterSeconds: retryAfter,
                      limit: limit,
                    ),
                  ),
                );
              }
              if (error.response?.statusCode == 401) {
                _redirectToLogin();
              }
              return handler.next(error);
            },
          ),
        );

  static void _parseRateLimitHeaders(Headers? headers) {
    if (headers == null) return;
    final limit = int.tryParse(headers.value('X-RateLimit-Limit') ?? '');
    final remaining = int.tryParse(
      headers.value('X-RateLimit-Remaining') ?? '',
    );
    final reset = int.tryParse(headers.value('X-RateLimit-Reset') ?? '');
    if (limit != null && remaining != null) {
      rateLimit.update(limit: limit, remaining: remaining, resetSeconds: reset);
    }
  }

  static Future<void> _redirectToLogin() async {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    rateLimit.clear();
    await SessionService.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    _isRedirectingToLogin = false;
  }
}
