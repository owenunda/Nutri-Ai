class GoogleAuthConfig {
  /// Client ID **web** de Google Cloud (termina en .apps.googleusercontent.com).
  /// Android lo necesita como serverClientId para devolver un idToken, y el
  /// backend lo acepta como audiencia. No es un secreto.
  /// Vacío hasta completar la Tarea 9; mientras tanto el botón muestra un error.
  static const String serverClientId = '';
}
