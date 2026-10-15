import 'package:flutter/material.dart';

import '../../../core/services/google_auth_service.dart';
import '../../../core/services/session_service.dart';
import '../../home/presentation/screens/dashboard_screen.dart';
import '../../setup/presentation/screens/profile_setup_screen.dart';
import '../data/auth_repository.dart';
import 'screens/set_password_screen.dart';

const _googleErrorMessage =
    'No se pudo iniciar sesión con Google. Inténtalo de nuevo.';

/// Entra con Google y abre la pantalla que corresponda. Devuelve el mensaje
/// de error a mostrar, o null si salió bien o el usuario cerró el selector.
Future<String?> signInWithGoogle(
  BuildContext context, {
  AuthRepository? repository,
}) async {
  try {
    final idToken = await GoogleAuthService.getIdToken();
    if (idToken == null) return null;

    final result = await (repository ?? AuthRepository()).loginWithGoogle(
      idToken,
    );
    await SessionService.save(token: result.token, user: result.user);

    if (!context.mounted) return null;
    openAppAfterLogin(
      context,
      result.user,
      needsProfileSetup: result.needsProfileSetup,
      offerPasswordSetup: result.offerPasswordSetup,
    );
    return null;
  } on GoogleAuthException catch (error) {
    return error.message;
  } on AuthException catch (error) {
    return error.message;
  } catch (_) {
    return _googleErrorMessage;
  }
}

/// Tras iniciar sesión: primero la oferta de crear contraseña si toca,
/// después el setup del perfil si falta, y si no el Dashboard.
void openAppAfterLogin(
  BuildContext context,
  Map<String, dynamic> user, {
  required bool needsProfileSetup,
  bool offerPasswordSetup = false,
}) {
  Widget nextScreen() => needsProfileSetup
      ? ProfileSetupScreen(userName: user['name']?.toString())
      : DashboardScreen(user: user);

  final destination = offerPasswordSetup
      ? SetPasswordScreen(nextScreen: nextScreen)
      : nextScreen();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}
