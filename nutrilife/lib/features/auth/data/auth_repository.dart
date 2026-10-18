import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;

  /// Código de error del backend (p. ej. `EMAIL_ALREADY_EXISTS`), si lo mandó.
  /// Sirve para decidir qué mostrar sin depender del idioma del mensaje.
  final String? code;

  @override
  String toString() => message;
}

/// El correo de Google ya tiene una cuenta con contraseña: para vincularla
/// hay que pedir esa contraseña.
class GoogleLinkRequiredException extends AuthException {
  const GoogleLinkRequiredException(super.message);
}

class GoogleLoginResult {
  const GoogleLoginResult({
    required this.token,
    required this.user,
    required this.needsProfileSetup,
    required this.offerPasswordSetup,
  });

  final String token;
  final Map<String, dynamic> user;

  /// true si el usuario no completó su perfil: hay que mandarlo al setup.
  final bool needsProfileSetup;

  /// true en el primer login con Google de una cuenta sin contraseña: se le
  /// ofrece crear una para poder entrar también con email.
  final bool offerPasswordSetup;
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
        _extractFriendlyMessage(data) ?? currentL10n.authErrorRegister,
      );
    } on DioException catch (error) {
      throw AuthException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error),
        code: _errorCode(error.response?.data),
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(currentL10n.authErrorRegister);
    }
  }

  /// Lanza [GoogleLinkRequiredException] si el correo ya tiene una cuenta con
  /// contraseña: hay que pedirla y llamar a [linkGoogle].
  Future<GoogleLoginResult> loginWithGoogle(String idToken) =>
      _postSession(
        ApiRoutes.authGoogle,
        {'idToken': idToken},
        currentL10n.authErrorGoogle,
      );

  /// Vincula Google a la cuenta existente con ese correo, confirmando su
  /// contraseña. La contraseña se conserva.
  Future<GoogleLoginResult> linkGoogle(String idToken, String password) =>
      _postSession(ApiRoutes.authGoogleLink, {
        'idToken': idToken,
        'password': password,
      }, currentL10n.authErrorGoogle);

  /// Verifica el correo con el código enviado y devuelve la sesión.
  Future<GoogleLoginResult> verifyEmail(String email, String code) =>
      _postSession(
        ApiRoutes.authVerifyEmail,
        {'email': email, 'code': code},
        currentL10n.authErrorVerifyEmail,
      );

  /// Reenvía el código para verificar el correo.
  Future<void> resendVerification(String email) => _post(
    ApiRoutes.authVerifyEmailResend,
    {'email': email},
    currentL10n.authErrorResendCode,
  );

  /// Envía un código para restablecer la contraseña.
  Future<void> forgotPassword(String email) => _post(
    ApiRoutes.authPasswordForgot,
    {'email': email},
    currentL10n.authErrorSendCode,
  );

  /// Pone una contraseña nueva usando el código enviado al correo.
  Future<void> resetPassword(String email, String code, String password) =>
      _post(
        ApiRoutes.authPasswordReset,
        {'email': email, 'code': code, 'password': password},
        currentL10n.authErrorResetPassword,
      );

  /// true si el backend tiene el modo invitado encendido. Ante cualquier
  /// fallo, false: el botón no aparece y el login sigue como siempre.
  Future<bool> isGuestModeEnabled() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.authHealth,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data?['data'];
      return data is Map && data['guestModeEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Crea una cuenta de invitado de 24 h y devuelve su sesión.
  Future<GoogleLoginResult> loginAsGuest() => _postSession(
    ApiRoutes.authGuest,
    const {},
    currentL10n.authErrorGuest,
  );

  /// POST que responde una sesión (`token`, `user`, banderas). También la usa
  /// la verificación del correo.
  Future<GoogleLoginResult> _postSession(
    String path,
    Map<String, dynamic> payload,
    String fallback,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: payload);

      final body = response.data;
      final data = body?['data'];
      if (body != null && body['success'] == true && data is Map<String, dynamic>) {
        return GoogleLoginResult(
          token: data['token'] as String,
          user: Map<String, dynamic>.from(data['user'] as Map),
          needsProfileSetup: data['needsProfileSetup'] == true,
          offerPasswordSetup: data['offerPasswordSetup'] == true,
        );
      }

      throw AuthException(_extractFriendlyMessage(body) ?? fallback);
    } on DioException catch (error) {
      final body = error.response?.data;
      final message =
          _extractFriendlyMessage(body) ??
          _fallbackMessage(error, defaultMessage: fallback);
      if (_errorCode(body) == 'GOOGLE_LINK_REQUIRES_PASSWORD') {
        throw GoogleLinkRequiredException(message);
      }
      throw AuthException(message);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(fallback);
    }
  }

  String? _errorCode(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final error = data['error'];
    return error is Map<String, dynamic> ? error['code'] as String? : null;
  }

  /// Crea la contraseña de la cuenta en sesión, que solo entraba con Google.
  Future<void> setPassword(String password) => _post(
    ApiRoutes.userPassword,
    {'password': password},
    currentL10n.authErrorSetPassword,
  );

  /// POST sin datos de respuesta: solo importa si salió bien.
  Future<void> _post(
    String path,
    Map<String, dynamic> payload,
    String fallback,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: payload);

      final body = response.data;
      if (body != null && body['success'] == true) {
        return;
      }

      throw AuthException(_extractFriendlyMessage(body) ?? fallback);
    } on DioException catch (error) {
      throw AuthException(
        _extractFriendlyMessage(error.response?.data) ??
            _fallbackMessage(error, defaultMessage: fallback),
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(fallback);
    }
  }

  String _fallbackMessage(DioException error, {String? defaultMessage}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return currentL10n.commonErrorTimeout;
      case DioExceptionType.connectionError:
        return currentL10n.commonErrorConnection;
      default:
        return defaultMessage ?? currentL10n.authErrorRegister;
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
