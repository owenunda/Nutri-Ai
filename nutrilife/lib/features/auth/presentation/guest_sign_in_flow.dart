import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/session_service.dart';
import '../data/auth_repository.dart';
import 'google_sign_in_flow.dart';

/// Crea la cuenta de invitado y abre la app. Devuelve el mensaje de error a
/// mostrar, o null si salió bien.
Future<String?> signInAsGuest(
  BuildContext context, {
  AuthRepository? repository,
}) async {
  try {
    final result = await (repository ?? AuthRepository()).loginAsGuest();
    await SessionService.save(token: result.token, user: result.user);

    if (!context.mounted) return null;
    openAppAfterLogin(
      context,
      result.user,
      needsProfileSetup: result.needsProfileSetup,
    );
    return null;
  } on AuthException catch (error) {
    return error.message;
  } catch (_) {
    return currentL10n.authErrorGuest;
  }
}
