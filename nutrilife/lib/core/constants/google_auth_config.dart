class GoogleAuthConfig {
  /// Client ID **web** de Google Cloud (termina en .apps.googleusercontent.com).
  /// Android lo necesita como serverClientId para devolver un idToken, y el
  /// backend lo acepta como audiencia. No es un secreto.
  static const String serverClientId =
      '989596167337-elpa3b076o6je6bnt1c255cfd4jks8do.apps.googleusercontent.com';
}
