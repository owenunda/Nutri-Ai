import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import 'google_auth_service.dart';
import 'purchase_service.dart';

class SessionService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  static Map<String, dynamic>? _user;

  /// true si la sesión actual es de una cuenta de invitado de la beta.
  static bool get isGuest => _user?['isGuest'] == true;

  /// Hasta cuándo dura la cuenta de invitado, en hora local.
  static DateTime? get guestExpiresAt => DateTime.tryParse(
    _user?['guestExpiresAt']?.toString() ?? '',
  )?.toLocal();

  // Ata las compras de RevenueCat a la cuenta de NutriLife, no al teléfono.
  // El backend manda el id como `userId`; `id` queda por sesiones viejas.
  // El invitado no compra: no se ata.
  static Future<void> _linkPurchases(Map<String, dynamic> user) async {
    if (user['isGuest'] == true) return;
    final id = (user['userId'] ?? user['id'])?.toString().trim();
    if (id != null && id.isNotEmpty) await PurchaseService.instance.logIn(id);
  }

  static Future<void> save({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_keyUser, jsonEncode(user));
      await prefs.setString(_keyToken, token);
      DioClient.authToken = token;
      _user = user;
      await _linkPurchases(user);
    } catch (_) {
      DioClient.authToken = null;
      _user = null;
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
      rethrow;
    }
  }

  static Future<({String token, Map<String, dynamic> user})?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);
    if (token == null || token.isEmpty || userJson == null) {
      await clear();
      return null;
    }

    try {
      final decodedUser = jsonDecode(userJson);
      if (decodedUser is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      DioClient.authToken = token;
      _user = decodedUser;
      // Sin await: no bloquear el arranque por la red de RevenueCat.
      unawaited(_linkPurchases(decodedUser));
      return (token: token, user: decodedUser);
    } on FormatException {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    DioClient.authToken = null;
    _user = null;
    await PurchaseService.instance.logOut();
    await GoogleAuthService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
