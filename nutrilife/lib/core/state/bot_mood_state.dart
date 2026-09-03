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

  // --- Gaze tracking -----------------------------------------------------
  // Mismo patron que pulse: el token cambia en cada llamada para que el
  // BotAvatar distinga dos updates seguidos del mismo (dx, dy) y reenvie al
  // motor. Las coordenadas son del espacio normalizado del bot (1.0 = radio
  // de la bola); el calculo del offset a partir de la posicion del tap en
  // pantalla vive en quien llama (la pantalla que tiene el tap listener).
  int _gazeTokenCounter = 0;
  Object? _gazeToken;
  double _gazeDx = 0;
  double _gazeDy = 0;
  Object? get gazeToken => _gazeToken;
  double get gazeDx => _gazeDx;
  double get gazeDy => _gazeDy;

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

  /// Apunta los ojos hacia un punto en espacio normalizado del bot
  /// (1.0 = radio de la bola). El motor suaviza hacia ese target.
  void setGaze(double dx, double dy) {
    if (dx == _gazeDx && dy == _gazeDy) return;
    _gazeDx = dx;
    _gazeDy = dy;
    _gazeToken = ++_gazeTokenCounter;
    notifyListeners();
  }
}
