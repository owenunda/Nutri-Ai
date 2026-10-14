import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';

void main() {
  RequestOptions request(String path, {String baseUrl = ''}) =>
      RequestOptions(path: path, baseUrl: baseUrl);

  group('shouldRedirectToLogin', () {
    test('401 en una ruta autenticada cierra la sesión', () {
      expect(shouldRedirectToLogin(request('/user/profile'), 401), isTrue);
    });

    test('401 en /auth/google no redirige', () {
      expect(shouldRedirectToLogin(request('/auth/google'), 401), isFalse);
    });

    test('401 en /auth/login no redirige', () {
      expect(shouldRedirectToLogin(request('/auth/login'), 401), isFalse);
    });

    test('403 en /user/account no redirige', () {
      expect(shouldRedirectToLogin(request('/user/account'), 403), isFalse);
    });

    test('con baseUrl con prefijo, /auth/* tampoco redirige', () {
      const base = 'https://api.example.com/api/v1';
      expect(
        shouldRedirectToLogin(request('/auth/google', baseUrl: base), 401),
        isFalse,
      );
      expect(
        shouldRedirectToLogin(request('/user/profile', baseUrl: base), 401),
        isTrue,
      );
    });

    test('sin código de estado no redirige', () {
      expect(shouldRedirectToLogin(request('/user/profile'), null), isFalse);
    });
  });
}
