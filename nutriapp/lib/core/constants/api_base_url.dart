import 'package:flutter/foundation.dart';

class ApiBaseUrl {
  static String get value {
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
