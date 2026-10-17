/// Mensajes del Chef IA que le quedan hoy al usuario, según el backend.
///
/// Para PRO y ADMIN [unlimited] es true y [limit], [used] y [remaining] vienen
/// null: el tope de uso justo de PRO no se muestra.
class ChatQuota {
  final bool unlimited;
  final int? limit;
  final int? used;
  final int? remaining;

  /// Próxima medianoche de Bogotá, en la hora local del teléfono.
  final DateTime? resetAt;

  /// Sin mensajes por hoy: el chat se bloquea hasta [resetAt].
  final bool exhausted;

  const ChatQuota({
    required this.unlimited,
    this.limit,
    this.used,
    this.remaining,
    this.resetAt,
    this.exhausted = false,
  });

  /// Lee el mapa `quota` del backend. Si no es un mapa, devuelve null.
  static ChatQuota? fromMap(Object? raw) {
    if (raw is! Map) return null;
    int? asInt(Object? value) => value is num ? value.toInt() : null;
    final resetAt = raw['resetAt'];
    return ChatQuota(
      unlimited: raw['unlimited'] == true,
      limit: asInt(raw['limit']),
      used: asInt(raw['used']),
      remaining: asInt(raw['remaining']),
      resetAt: resetAt is String ? DateTime.tryParse(resetAt)?.toLocal() : null,
      exhausted: raw['exhausted'] == true,
    );
  }
}

/// El usuario usó sus mensajes del día (FREE) o llegó al tope de uso justo
/// (PRO). No confundir con RateLimitException, que es el límite por minuto.
class ChatQuotaExceededException implements Exception {
  final ChatQuota quota;

  const ChatQuotaExceededException(this.quota);

  bool get isFairUse => quota.unlimited;

  @override
  String toString() => 'ChatQuotaExceededException(fairUse: $isFairUse)';
}
