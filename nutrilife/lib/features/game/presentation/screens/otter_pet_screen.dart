import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/otter_sprite.dart';

/// La nutria tipo tamagotchi. Por ahora solo se acaricia: hay que pasar el
/// dedo por encima de ella; un toque sin mover el dedo no cuenta.
class OtterPetScreen extends StatefulWidget {
  const OtterPetScreen({super.key});

  @override
  State<OtterPetScreen> createState() => _OtterPetScreenState();
}

class _Heart {
  _Heart(this.origin, this.drift, this.born);

  final Offset origin;
  final double drift;
  final Duration born;
}

class _OtterPetScreenState extends State<OtterPetScreen>
    with SingleTickerProviderStateMixin {
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

  late final Ticker _ticker;
  final _random = math.Random();
  final _hearts = <_Heart>[];
  Duration _now = Duration.zero;
  Duration? _lastStroke;
  Duration? _happySince;
  double _petDistance = 0;
  double _sinceHeart = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _now = elapsed;
        _hearts.removeWhere((h) => _now - h.born > _heartLife);
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _isHappy =>
      _happySince != null && _now - _happySince! < _happyDuration;

  bool get _isPetted =>
      _lastStroke != null && _now - _lastStroke! < _strokeGrace;

  void _onPointerMove(PointerMoveEvent e) {
    if (_isHappy) return;
    // El sprite tiene margen transparente: solo cuenta el roce sobre el cuerpo.
    final body = (Offset.zero & const Size.square(_otterSize))
        .deflate(_otterSize * 0.15);
    if (!body.contains(e.localPosition)) return;

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
      _addHeart(Offset(
        _otterSize * (0.3 + 0.4 * _random.nextDouble()),
        _otterSize * (0.25 + 0.3 * _random.nextDouble()),
      ));
    }
    HapticFeedback.mediumImpact();
  }

  void _addHeart(Offset at) =>
      _hearts.add(_Heart(at, (_random.nextDouble() - 0.5) * 60, _now));

  (String, int) get _sprite {
    if (_isHappy) {
      final frame = (_now - _happySince!).inMilliseconds * _happyFps ~/ 1000;
      return (OtterSprite.happinessSheet, frame.clamp(0, 5));
    }
    // Cuadro del parpadeo: ojos cerrados y sonrisa, como quien disfruta.
    if (_isPetted) return (OtterSprite.idleSheet, 2);
    final ms = _now.inMilliseconds % (_idleRestMs + 6 * 1000 ~/ _idleFps);
    final frame = ms < _idleRestMs ? 0 : (ms - _idleRestMs) * _idleFps ~/ 1000;
    return (OtterSprite.idleSheet, frame.clamp(0, 5));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (sheet, frame) = _sprite;
    final showHappyText =
        _happySince != null && _now - _happySince! < _happyMessage;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.gameTitle,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Para lectores de pantalla el gesto no sirve: un toque doble
              // equivale a una caricia completa.
              Semantics(
                label: l10n.gamePetHint,
                onTap: () => setState(_celebrate),
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
                            sheet: sheet,
                            frame: frame,
                            size: _otterSize,
                          ),
                        ),
                        for (final heart in _hearts) _buildHeart(heart),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                showHappyText ? l10n.gamePetHappy : l10n.gamePetHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeart(_Heart heart) {
    final t = (_now - heart.born).inMicroseconds / _heartLife.inMicroseconds;
    return Positioned(
      left: heart.origin.dx + heart.drift * t - 12,
      top: heart.origin.dy - 90 * t - 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: (1 - t).clamp(0, 1),
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF6B8B),
            size: 24,
          ),
        ),
      ),
    );
  }
}
