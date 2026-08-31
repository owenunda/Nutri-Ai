enum BotMood { idle, thinking, pleased, surprised, sleeping }

extension BotMoodX on BotMood {
  /// Los transitorios se disparan con pulse() y vuelven solos a idle.
  bool get isTransient => this == BotMood.pleased || this == BotMood.surprised;
}
