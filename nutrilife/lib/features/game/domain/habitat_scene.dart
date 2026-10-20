import '../../../core/l10n/l10n.dart';

/// Un lugar donde vive la nutria. Cada uno tiene versión de día y de noche en
/// `assets/game/habitat/<id>_dia.webp` y `<id>_noche.webp`.
class HabitatScene {
  const HabitatScene._(this.id, this.label, {this.hasLamp = false});

  final String id;
  final String Function(AppLocalizations l10n) label;

  /// Si cuelga el foco que se prende y se apaga. Solo bajo techo.
  final bool hasLamp;

  String get dayAsset => 'assets/game/habitat/${id}_dia.webp';
  String get nightAsset => 'assets/game/habitat/${id}_noche.webp';

  static final habitacion = HabitatScene._(
    'habitacion',
    (l) => l.gamePlaceHabitacion,
    hasLamp: true,
  );
  static final bosque = HabitatScene._('bosque', (l) => l.gamePlaceBosque);
  static final costa = HabitatScene._('costa', (l) => l.gamePlaceCosta);
  static final montana = HabitatScene._('montana', (l) => l.gamePlaceMontana);
  static final espacioBasico = HabitatScene._(
    'espacio_basico',
    (l) => l.gamePlaceEspacioBasico,
  );
  static final espacioAurora = HabitatScene._(
    'espacio_aurora',
    (l) => l.gamePlaceEspacioAurora,
  );
  static final espacioOro = HabitatScene._(
    'espacio_oro',
    (l) => l.gamePlaceEspacioOro,
  );
  static final espacioDiamante = HabitatScene._(
    'espacio_diamante',
    (l) => l.gamePlaceEspacioDiamante,
  );

  /// Orden en que se muestran en "Lugares".
  static final all = [
    habitacion,
    bosque,
    costa,
    montana,
    espacioBasico,
    espacioAurora,
    espacioOro,
    espacioDiamante,
  ];

  /// El lugar con ese id, o la habitación si no existe.
  static HabitatScene byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => habitacion);

  /// De día entre las 6:00 y las 18:59 del teléfono.
  static bool isNightAt(DateTime time) => time.hour < 6 || time.hour >= 19;
}
