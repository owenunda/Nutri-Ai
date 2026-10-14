// Cuándo toca un intersticial tras registrar comida: como mucho uno cada
// [logsPerAd] registros y nunca dos en menos de [minInterval]. Separado del
// SDK para poder probarlo con un reloj falso.
class InterstitialPolicy {
  InterstitialPolicy({
    this.logsPerAd = 3,
    this.minInterval = const Duration(minutes: 3),
  });

  final int logsPerAd;
  final Duration minInterval;

  int _logsSinceAd = 0;
  DateTime? _lastShownAt;

  // Cuenta un registro y dice si ahora corresponde mostrar el anuncio.
  // El contador solo se reinicia con [markShown]: si el anuncio no estaba
  // cargado, el siguiente registro lo vuelve a intentar.
  bool onMealLogged(DateTime now) {
    _logsSinceAd++;
    if (_logsSinceAd < logsPerAd) return false;

    final last = _lastShownAt;
    return last == null || now.difference(last) >= minInterval;
  }

  void markShown(DateTime now) {
    _logsSinceAd = 0;
    _lastShownAt = now;
  }
}
