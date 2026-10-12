import 'package:flutter/foundation.dart';

/// Avisa que cambió lo registrado (comidas o peso). Inicio y Progreso lo
/// escuchan para recargar sin que el usuario tenga que tirar para refrescar.
class MealLogState extends ChangeNotifier {
  MealLogState._();

  static final MealLogState instance = MealLogState._();

  int _revision = 0;
  int get revision => _revision;

  void bump() {
    _revision++;
    notifyListeners();
  }
}
