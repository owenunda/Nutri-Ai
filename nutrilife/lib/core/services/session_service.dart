import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';

class SessionService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  static Future<void> save({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_keyUser, jsonEncode(user));
      await prefs.setString(_keyToken, token);
      DioClient.authToken = token;
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
      return (token: token, user: decodedUser);
    } on FormatException {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    DioClient.authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
