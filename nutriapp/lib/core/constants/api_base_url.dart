import 'package:flutter/foundation.dart';

class ApiBaseUrl {
  static String get value {
    if (kReleaseMode) {
      // Reemplaza esta URL con tu servidor de producción real
      return 'https://api.tu-servidor-produccion.com/api/v1';
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api/v1';
      default:
        return 'http://localhost:3000/api/v1';
    }
  }
}
