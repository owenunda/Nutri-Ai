import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_base_url.dart';
import '../l10n/l10n.dart';
import '../navigation/navigator_key.dart';
import '../state/locale_state.dart';
import 'api_routes.dart';
import '../services/session_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'rate_limit_state.dart';

/// Decide si una respuesta de error debe cerrar la sesión y mandar al login.
///
/// Solo un 401 en una ruta autenticada significa "sesión caducada". Los 401
/// de `/auth/*` (token de Google inválido, contraseña incorrecta) llegan con
/// el usuario aún sin sesión: redirigir borraría el mensaje que el panel de
/// login está a punto de mostrar.
bool shouldRedirectToLogin(RequestOptions options, int? statusCode) {
  if (statusCode != 401) return false;

  // `options.uri` resuelve rutas relativas y absolutas; se le quita el
  // prefijo del baseUrl (p. ej. /api/v1) para comparar solo la ruta del API.
  final fullPath = options.uri.path;
  final basePath =
      Uri.tryParse(options.baseUrl)?.path.replaceAll(RegExp(r'/+$'), '') ?? '';
  final apiPath = basePath.isNotEmpty && fullPath.startsWith(basePath)
      ? fullPath.substring(basePath.length)
      : fullPath;

  return !apiPath.startsWith('/auth/');
}

/// true si el 401 dice que venció la cuenta de invitado: el login lo avisa.
bool isGuestExpiredResponse(dynamic body) {
  if (body is! Map) return false;
  final error = body['error'];
  return error is Map && error['code'] == 'GUEST_EXPIRED';
}

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
              final isPublicAuthRequest =
                  options.path == ApiRoutes.authLogin ||
                  options.path == ApiRoutes.authRegister;
              if (!isPublicAuthRequest && authToken != null) {
                options.headers['Authorization'] = 'Bearer $authToken';
              }
              // El backend responde errores, correos y el chat en este idioma.
              options.headers['Accept-Language'] =
                  LocaleState.instance.languageCode;
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
              // Solo cierra la sesión si la petición iba autenticada y no es
              // de /auth/*: un 401 sin token no es una sesión caducada.
              final authorization =
                  error.requestOptions.headers['Authorization'];
              final hadBearerToken =
                  authorization is String && authorization.startsWith('Bearer ');
              if (hadBearerToken &&
                  shouldRedirectToLogin(
                    error.requestOptions,
                    error.response?.statusCode,
                  )) {
                _redirectToLogin(
                  guestExpired: isGuestExpiredResponse(error.response?.data),
                );
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

  static Future<void> _redirectToLogin({bool guestExpired = false}) async {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    rateLimit.clear();
    await SessionService.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          notice: guestExpired ? currentL10n.authGuestExpired : null,
        ),
      ),
      (route) => false,
    );
    _isRedirectingToLogin = false;
  }
}
