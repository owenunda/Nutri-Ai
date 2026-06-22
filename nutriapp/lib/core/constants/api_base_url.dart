import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiBaseUrl {
  static String get value {
    if (kDebugMode) {
      return Platform.isAndroid ? 'http://10.0.2.2:3000/api/v1' : 'http://localhost:3000/api/v1';
    }
    return 'https://api.nutri.oween.software/api/v1';
  }
}

