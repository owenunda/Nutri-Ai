import '../../../core/l10n/l10n.dart';

/// Una nutria de la colección. Cada una vive en `assets/game/otters/<id>/`
/// con los mismos spritesheets (ver lib/features/game/README.md).
class OtterSkin {
  const OtterSkin._(this.id, this.label, {this.petFrame = 2});

  final String id;
  final String Function(AppLocalizations l10n) label;

  /// Cuadro de `idle` que se muestra mientras la acarician: el de ojos
  /// cerrados y sonrisa. No es el mismo en todas las nutrias.
  final int petFrame;

  String get idleSheet => 'assets/game/otters/$id/idle.webp';
  String get happinessSheet => 'assets/game/otters/$id/happiness.webp';

  static final normal = OtterSkin._('normal', (l) => l.gameSkinNormal);
  static final chef = OtterSkin._('chef', (l) => l.gameSkinChef);
  static final deportiva = OtterSkin._('deportiva', (l) => l.gameSkinDeportiva);
  static final alienMint = OtterSkin._(
    'alien_mint',
    (l) => l.gameSkinAlienMint,
    petFrame: 1,
  );
  static final arcadeRacer = OtterSkin._(
    'arcade_racer',
    (l) => l.gameSkinArcadeRacer,
    petFrame: 3,
  );
  // Ningún cuadro de su idle cierra los ojos: se queda con el de reposo.
  static final galaxia = OtterSkin._(
    'galaxia',
    (l) => l.gameSkinGalaxia,
    petFrame: 0,
  );
  static final rpgExplorer = OtterSkin._(
    'rpg_explorer',
    (l) => l.gameSkinRpgExplorer,
    petFrame: 1,
  );

  /// Orden en que se muestran en la colección.
  static final all = [
    normal,
    chef,
    deportiva,
    alienMint,
    arcadeRacer,
    galaxia,
    rpgExplorer,
  ];

  /// La nutria con ese id, o la normal si no existe (por ejemplo, una que se
  /// guardó en otra versión y ya no está en el catálogo).
  static OtterSkin byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => normal);
}
