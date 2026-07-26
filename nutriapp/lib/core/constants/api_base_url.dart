import 'package:flutter/foundation.dart';

class ApiBaseUrl {
  static String get value {
    if (kDebugMode) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'https://api.nutri.oween.software/api/v1';
  }
}
