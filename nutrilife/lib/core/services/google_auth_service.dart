import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_auth_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Envuelve google_sign_in: abre el selector de cuentas y devuelve el idToken
/// que el backend verifica. Lo usan el login y el borrado de la cuenta.
class GoogleAuthService {
  GoogleAuthService._();

  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() async {
    _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    try {
      await _initialization;
    } catch (_) {
      // Permite reintentar si falló (p. ej. sin Google Play Services).
      _initialization = null;
      rethrow;
    }
  }

  /// Devuelve el idToken, o null si el usuario cierra el selector.
  static Future<String?> getIdToken() async {
    if (GoogleAuthConfig.serverClientId.isEmpty) {
      throw const GoogleAuthException(
        'El inicio de sesión con Google no está configurado.',
      );
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const GoogleAuthException(
          'Google no devolvió tus datos. Inténtalo de nuevo.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw const GoogleAuthException(
        'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
      );
    }
  }

  /// Olvida la cuenta elegida para que el próximo inicio muestre el selector.
  static Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Cerrar la sesión de la app no debe fallar por Google.
    }
  }
}
