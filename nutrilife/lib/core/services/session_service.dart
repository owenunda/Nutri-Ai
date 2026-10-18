import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import 'google_auth_service.dart';
import 'purchase_service.dart';

class SessionService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  // Ata las compras de RevenueCat a la cuenta de NutriLife, no al teléfono.
  static Future<void> _linkPurchases(Map<String, dynamic> user) async {
    final id = user['id']?.toString().trim();
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
      await _linkPurchases(user);
    } catch (_) {
      DioClient.authToken = null;
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
    await PurchaseService.instance.logOut();
    await GoogleAuthService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
