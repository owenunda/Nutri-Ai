import 'package:flutter/foundation.dart';

import '../../features/bot/domain/bot_mood.dart';

/// Puente entre el chat y la nav bar. Sigue el patron de DioClient.rateLimit:
/// un ChangeNotifier compartido, sin meter provider en el proyecto.
class BotMoodState extends ChangeNotifier {
  static final BotMoodState instance = BotMoodState();

  BotMood _mood = BotMood.idle;
  BotMood get mood => _mood;

  int _token = 0;
  Object? _pulseToken;
  BotMood? _pulseMood;
  Object? get pulseToken => _pulseToken;
  BotMood? get pulseMood => _pulseMood;

  /// Fija un mood sostenido (idle, thinking, sleeping).
  void hold(BotMood m) {
    if (m.isTransient) return;
    if (m == _mood) return;
    _mood = m;
    notifyListeners();
  }

  /// Dispara un mood transitorio (pleased, surprised). El token cambia en cada
  /// llamada para que el widget distinga dos pulses seguidos del mismo tipo.
  void pulse(BotMood m) {
    if (!m.isTransient) return;
    _pulseMood = m;
    _pulseToken = ++_token;
    notifyListeners();
  }
}
