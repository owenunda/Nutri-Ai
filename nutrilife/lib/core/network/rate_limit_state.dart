import 'package:flutter/foundation.dart';

class RateLimitException implements Exception {
  final int retryAfterSeconds;
  final int limit;
  RateLimitException({required this.retryAfterSeconds, required this.limit});

  @override
  String toString() =>
      'RateLimitException(límite $limit alcanzado, reintenta en ${retryAfterSeconds}s)';
}

class RateLimitState extends ChangeNotifier {
  int? limit;
  int? remaining;
  int? resetSeconds;
  bool _wasNearLimit = false;

  bool get hasInfo => limit != null && remaining != null;
  bool get isLow => hasInfo && remaining! <= 2;
  bool get isExhausted => hasInfo && remaining! <= 0;

  void update({
    required int? limit,
    required int? remaining,
    required int? resetSeconds,
  }) {
    this.limit = limit;
    this.remaining = remaining;
    this.resetSeconds = resetSeconds;

    final near = isLow;
    if (near != _wasNearLimit) {
      _wasNearLimit = near;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void clear() {
    limit = null;
    remaining = null;
    resetSeconds = null;
    _wasNearLimit = false;
    notifyListeners();
  }
}