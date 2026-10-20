import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/game_preferences.dart';
import '../../domain/habitat_scene.dart';
import '../../domain/otter_skin.dart';
import '../widgets/game_picker_sheet.dart';
import '../widgets/otter_sprite.dart';

/// La nutria tipo tamagotchi. Se acaricia pasando el dedo por encima (un
/// toque sin mover el dedo no cuenta), duerme y despierta, se elige qué nutria
/// y en qué lugar vive, y el lugar cambia entre día y noche.
class OtterPetScreen extends StatefulWidget {
  const OtterPetScreen({super.key});

  @override
  State<OtterPetScreen> createState() => _OtterPetScreenState();
}

/// Algo que sube y se desvanece sobre la nutria: un corazón o una "z".
class _Heart {
  _Heart(this.origin, this.drift, this.born, {this.isZ = false});

  final Offset origin;
  final double drift;
  final Duration born;
  final bool isZ;
}

class _OtterPetScreenState extends State<OtterPetScreen>
    with SingleTickerProviderStateMixin {
  static const _lampOnAsset = 'assets/game/habitat/foco_encendido.webp';
  static const _lampOffAsset = 'assets/game/habitat/foco_apagado.webp';
  static const _lampWidth = 96.0;
  static const _lampHeight = _lampWidth * 521 / 270; // proporción del WebP
  static const _bubbleAsset = 'assets/game/habitat/globo_dialogo.png';
  static const _bubbleWidth = 220.0;
  static const _bubbleHeight = _bubbleWidth * 304 / 454; // proporción del PNG
  static const _otterSize = 280.0;
  static const _heartEvery = 60.0; // px de caricia entre corazón y corazón
  static const _petsToHappy = 900.0; // px de caricia para que salte de alegría
  static const _strokeGrace = Duration(milliseconds: 150);
  // Más lentos que los animation.json (8 y 10 fps): con 6 cuadros se veían acelerados.
  static const _idleFps = 6;
  // En reposo se queda quieta y cada tanto hace la secuencia una vez: si el
  // bucle no para, los 6 cuadros (todos distintos) parecen un temblor.
  static const _idleRestMs = 3500;
  static const _happyFps = 6;
  static const _happyDuration = Duration(milliseconds: 6 * 1000 ~/ _happyFps);
  static const _happyMessage = Duration(seconds: 2);
  static const _heartLife = Duration(milliseconds: 1000);
  static const _sleepFps = 6;
  // sleep y wake tienen 6 cuadros y se reproducen una sola vez.
  static const _sleepDuration = Duration(milliseconds: 6 * 1000 ~/ _sleepFps);
  static const _zEvery = Duration(milliseconds: 900);
  static const _zLife = Duration(milliseconds: 2000);
  static const _strokeToWake = 150.0; // px de caricia para despertarla

  late final Ticker _ticker;
  final _prefs = GamePreferences();
  // null hasta leer lo elegido: así no se ve un instante otra nutria u otro lugar.
  OtterSkin? _skin;
  HabitatScene? _scene;
  // Sigue la hora del teléfono; el botón de sol/luna la cambia a mano.
  bool _night = HabitatScene.isNightAt(DateTime.now());
  // De noche la luz empieza prendida; apagada, la habitación queda a oscuras.
  late bool _lampOn = _night;
  final _random = math.Random();
  final _hearts = <_Heart>[];
  Duration _now = Duration.zero;
  Duration? _lastStroke;
  Duration? _happySince;
  double _petDistance = 0;
  double _sinceHeart = 0;
  // Dormida desde ese momento; null = despierta.
  Duration? _sleepSince;
  Duration? _wakeSince;
  Duration? _lastZ;
  double _wakeDistance = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _now = elapsed;
        _hearts.removeWhere(
          (h) => _now - h.born > (h.isZ ? _zLife : _heartLife),
        );
        _addZIfDue();
      });
    })..start();
    // El hábitat está pensado en vertical: de lado la nutria no cae en la alfombra.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _prefs.load().then((saved) {
      if (!mounted) return;
      setState(() {
        _skin = saved.skin;
        _scene = saved.scene;
      });
    });
  }

  Future<void> _pickSkin() async {
    final current = _skin;
    if (current == null) return;
    final l10n = context.l10n;
    final picked = await showGamePickerSheet(
      context,
      title: l10n.gameCollectionTitle,
      subtitle: l10n.gameCollectionSubtitle,
      options: OtterSkin.all,
      selected: current,
      label: (skin) => skin.label(l10n),
      preview: (skin) => OtterSprite(sheet: skin.idleSheet, frame: 0, size: 92),
    );
    if (picked == null || picked == _skin || !mounted) return;
    setState(() {
      _skin = picked;
      _happySince = null;
      _petDistance = 0;
    });
    await _prefs.saveSkin(picked);
  }

  Future<void> _pickScene() async {
    final current = _scene;
    if (current == null) return;
    final l10n = context.l10n;
    final picked = await showGamePickerSheet(
      context,
      title: l10n.gamePlacesTitle,
      subtitle: l10n.gamePlacesSubtitle,
      options: HabitatScene.all,
      selected: current,
      label: (scene) => scene.label(l10n),
      preview: (scene) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        // cacheWidth: la miniatura no necesita decodificar 1440x2560.
        child: Image.asset(
          _night ? scene.nightAsset : scene.dayAsset,
          fit: BoxFit.cover,
          cacheWidth: 276,
        ),
      ),
    );
    if (picked == null || picked == _scene || !mounted) return;
    setState(() => _scene = picked);
    await _prefs.saveScene(picked);
  }

  void _toggleNight() => setState(() {
    _night = !_night;
    _lampOn = _night;
    // Amanece: se despierta. Anochecer no la duerme: la luz empieza prendida.
    if (!_night) _wake();
  });

  // De noche en la habitación, el foco también la duerme y la despierta.
  void _toggleLamp() => setState(() {
    _lampOn = !_lampOn;
    if (!_night) return;
    _lampOn ? _wake() : _sleep();
  });

  void _toggleSleep() => setState(() => _isAsleep ? _wake() : _sleep());

  bool get _isAsleep => _sleepSince != null;

  bool get _isWaking =>
      _wakeSince != null && _now - _wakeSince! < _sleepDuration;

  void _sleep() {
    if (_isAsleep) return;
    _sleepSince = _now;
    _wakeSince = null;
    _happySince = null;
    _lastStroke = null;
    _petDistance = 0;
    _wakeDistance = 0;
  }

  void _wake() {
    if (!_isAsleep) return;
    _sleepSince = null;
    _wakeSince = _now;
    _lastZ = null;
  }

  // Ya acostada, cada tanto sale una "z" por encima de su cabeza.
  void _addZIfDue() {
    if (!_isAsleep || _now - _sleepSince! < _sleepDuration) return;
    if (_lastZ != null && _now - _lastZ! < _zEvery) return;
    _lastZ = _now;
    _hearts.add(
      _Heart(
        const Offset(_otterSize * 0.7, _otterSize * 0.4),
        20 + _random.nextDouble() * 20,
        _now,
        isZ: true,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _ticker.dispose();
    super.dispose();
  }

  bool get _isHappy =>
      _happySince != null && _now - _happySince! < _happyDuration;

  bool get _isPetted =>
      _lastStroke != null && _now - _lastStroke! < _strokeGrace;

  void _onPointerMove(PointerMoveEvent e) {
    if (_isHappy || _isWaking) return;
    // El sprite tiene margen transparente: solo cuenta el roce sobre el cuerpo.
    final body = (Offset.zero & const Size.square(_otterSize)).deflate(
      _otterSize * 0.15,
    );
    if (!body.contains(e.localPosition)) return;

    // Dormida, una caricia suave la despierta en vez de sumar corazones.
    if (_isAsleep) {
      _wakeDistance += e.delta.distance;
      if (_wakeDistance >= _strokeToWake) _wake();
      return;
    }

    final distance = e.delta.distance;
    _lastStroke = _now;
    _petDistance += distance;
    _sinceHeart += distance;
    if (_sinceHeart >= _heartEvery) {
      _sinceHeart = 0;
      _addHeart(e.localPosition);
      HapticFeedback.selectionClick();
    }
    if (_petDistance >= _petsToHappy) _celebrate();
  }

  void _celebrate() {
    _happySince = _now;
    _petDistance = 0;
    _lastStroke = null;
    for (var i = 0; i < 8; i++) {
      _addHeart(
        Offset(
          _otterSize * (0.3 + 0.4 * _random.nextDouble()),
          _otterSize * (0.25 + 0.3 * _random.nextDouble()),
        ),
      );
    }
    HapticFeedback.mediumImpact();
  }

  void _addHeart(Offset at) =>
      _hearts.add(_Heart(at, (_random.nextDouble() - 0.5) * 60, _now));

  (String, int) _sprite(OtterSkin skin) {
    // Se acuesta una vez y se queda en el último cuadro mientras duerme.
    if (_isAsleep) {
      final frame = (_now - _sleepSince!).inMilliseconds * _sleepFps ~/ 1000;
      return (skin.sleepSheet, frame.clamp(0, 5));
    }
    if (_isWaking) {
      final frame = (_now - _wakeSince!).inMilliseconds * _sleepFps ~/ 1000;
      return (skin.wakeSheet, frame.clamp(0, 5));
    }
    if (_isHappy) {
      final frame = (_now - _happySince!).inMilliseconds * _happyFps ~/ 1000;
      return (skin.happinessSheet, frame.clamp(0, 5));
    }
    // Ojos cerrados y sonrisa, como quien disfruta.
    if (_isPetted) return (skin.idleSheet, skin.petFrame);
    final ms = _now.inMilliseconds % (_idleRestMs + 6 * 1000 ~/ _idleFps);
    final frame = ms < _idleRestMs ? 0 : (ms - _idleRestMs) * _idleFps ~/ 1000;
    return (skin.idleSheet, frame.clamp(0, 5));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skin = _skin;
    final scene = _scene;
    final sprite = skin == null ? null : _sprite(skin);
    final dark = scene != null && scene.hasLamp && _night && !_lampOn;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      // Todo lo de la barra va sobre blanco: sin eso no se lee sobre el fondo.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? Center(
                child: _barButton(
                  icon: const BackButtonIcon(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                ),
              )
            : null,
        title: _pill(
          Text(
            l10n.gameTitle,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          _barButton(
            icon: const Icon(Icons.landscape_rounded),
            tooltip: l10n.gameChangePlace,
            onPressed: _pickScene,
          ),
          _barButton(
            icon: Icon(
              _night ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: _night ? l10n.gameShowDay : l10n.gameShowNight,
            onPressed: _toggleNight,
          ),
          _barButton(
            icon: const Icon(Icons.checkroom_rounded),
            tooltip: l10n.gameChangeOtter,
            onPressed: _pickSkin,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          // Los pies de la nutria (~95 % del cuadro) van sobre la alfombra del
          // fondo (~87 % del alto). En teléfonos el fondo se escala por la
          // altura, así que esa proporción se mantiene.
          final otterLeft = (box.maxWidth - _otterSize) / 2;
          final otterTop = box.maxHeight * 0.87 - _otterSize * 0.95;
          return Stack(
            children: [
              if (scene != null)
                Positioned.fill(
                  child: Image.asset(
                    _night ? scene.nightAsset : scene.dayAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    // Sin hueco en blanco al cambiar de lugar o de día a noche.
                    gaplessPlayback: true,
                  ),
                ),
              if (sprite != null)
                Positioned(
                  left: otterLeft,
                  top: otterTop,
                  // Para lectores de pantalla el gesto no sirve: un toque doble
                  // equivale a una caricia completa.
                  child: Semantics(
                    label: l10n.gamePetHint,
                    onTap: () => setState(_isAsleep ? _wake : _celebrate),
                    child: Listener(
                      onPointerMove: _onPointerMove,
                      child: SizedBox.square(
                        dimension: _otterSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: _isPetted ? 0.96 : 1,
                              alignment: Alignment.bottomCenter,
                              duration: const Duration(milliseconds: 120),
                              child: OtterSprite(
                                sheet: sprite.$1,
                                frame: sprite.$2,
                                size: _otterSize,
                              ),
                            ),
                            for (final heart in _hearts) _buildHeart(heart),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (dark)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color(0x8C000000)),
                  ),
                ),
              if (scene != null && scene.hasLamp)
                // Cuelga desde arriba, entre el botón de volver y el título.
                Positioned(
                  top: 0,
                  left: box.maxWidth * 0.25 - _lampWidth / 2,
                  child: Semantics(
                    button: true,
                    label: _lampOn ? l10n.gameLampOff : l10n.gameLampOn,
                    child: GestureDetector(
                      onTap: _toggleLamp,
                      child: Image.asset(
                        _lampOn ? _lampOnAsset : _lampOffAsset,
                        width: _lampWidth,
                        height: _lampHeight,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _pill(
                        _hintText(
                          _isAsleep ? l10n.gameSleepingHint : l10n.gamePetHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _barButton(
                      icon: Icon(
                        _isAsleep
                            ? Icons.wb_sunny_rounded
                            : Icons.bedtime_rounded,
                      ),
                      tooltip: _isAsleep ? l10n.gameWake : l10n.gameSleep,
                      onPressed: _toggleSleep,
                    ),
                  ],
                ),
              ),
              if (_happySince != null && _now - _happySince! < _happyMessage)
                // La punta del globo (abajo, a ~25 % de su ancho) apunta a la
                // cabeza de la nutria; en pantallas angostas no se sale.
                Positioned(
                  left: math.min(
                    box.maxWidth / 2 + 10 - _bubbleWidth * 0.25,
                    box.maxWidth - _bubbleWidth - 8,
                  ),
                  top: otterTop + _otterSize * 0.12 - _bubbleHeight,
                  child: _buildBubble(l10n.gamePetHappy),
                ),
            ],
          );
        },
      ),
    );
  }

  static final _onScene = Colors.white.withValues(alpha: 0.85);

  /// Píldora blanca semitransparente para que el texto se lea sobre el fondo.
  Widget _pill(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _onScene,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _hintText(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: AppTheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _barButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppTheme.onSurface,
      style: IconButton.styleFrom(backgroundColor: _onScene),
    );
  }

  /// Globo de diálogo: aparece con un rebote y se desvanece al final.
  Widget _buildBubble(String text) {
    final age = (_now - _happySince!).inMilliseconds;
    final pop = Curves.easeOutBack.transform((age / 250).clamp(0.0, 1.0));
    final fade = ((_happyMessage.inMilliseconds - age) / 300).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: pop,
          alignment: const Alignment(-0.5, 1),
          child: SizedBox(
            width: _bubbleWidth,
            height: _bubbleHeight,
            child: Stack(
              children: [
                Image.asset(
                  _bubbleAsset,
                  width: _bubbleWidth,
                  height: _bubbleHeight,
                  filterQuality: FilterQuality.none,
                ),
                // El cuerpo del globo es el 86 % de arriba; el resto es la punta.
                Positioned.fill(
                  bottom: _bubbleHeight * 0.14,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: Color(0xFF43271B),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeart(_Heart heart) {
    final life = heart.isZ ? _zLife : _heartLife;
    final t = (_now - heart.born).inMicroseconds / life.inMicroseconds;
    return Positioned(
      left: heart.origin.dx + heart.drift * t - 12,
      top: heart.origin.dy - 90 * t - 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: (1 - t).clamp(0, 1),
          child: heart.isZ
              ? Text(
                  'z',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    // Crecen al subir, como en los dibujos animados.
                    fontSize: 18 + 14 * t,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4F5FB8),
                    shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                  ),
                )
              : const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF6B8B),
                  size: 24,
                ),
        ),
      ),
    );
  }
}
