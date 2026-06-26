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
    DioClient.authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  static Future<({String token, Map<String, dynamic> user})?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);
    if (token == null || userJson == null) return null;
    return (
      token: token,
      user: jsonDecode(userJson) as Map<String, dynamic>,
    );
  }

  static Future<void> clear() async {
    DioClient.authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
