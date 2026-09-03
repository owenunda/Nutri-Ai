// Widget con estado que envuelve BotEngine + BotPainter y los anima con un
// Ticker. Vive en presentation/ porque, a diferencia del motor (dart puro),
// aqui si hace falta el binding de UI de Flutter.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/bot_engine.dart';
import '../domain/bot_frame.dart';
import '../domain/bot_mood.dart';
import 'bot_painter.dart';

class BotAvatar extends StatefulWidget {
  final BotMood mood;

  /// Cambia a un valor nuevo para disparar un mood transitorio una sola vez.
  /// Usa un contador o un objeto nuevo cada vez; no basta con repetir el mismo
  /// enum, porque el widget compara por igualdad.
  final Object? pulseToken;
  final BotMood? pulseMood;

  /// Mismo patron que pulseToken: cambia en cada update del target de gaze.
  /// gazeDx/gazeDy en espacio normalizado del bot (1.0 = radio de la bola).
  final Object? gazeToken;
  final double gazeDx;
  final double gazeDy;

  final double size;
  final Color bodyColor;
  final Color eyeColor;

  const BotAvatar({
    super.key,
    required this.mood,
    this.pulseToken,
    this.pulseMood,
    this.gazeToken,
    this.gazeDx = 0,
    this.gazeDy = 0,
    this.size = 50,
    this.bodyColor = const Color(0xFFFFFFFF),
    this.eyeColor = const Color(0xFF134E32),
  });

  @override
  State<BotAvatar> createState() => _BotAvatarState();
}

class _BotAvatarState extends State<BotAvatar> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final BotEngine _engine = BotEngine();
  late BotFrame _frame;
  Duration _ultimoPintado = Duration.zero;

  @override
  void initState() {
    super.initState();
    _engine.hold(widget.mood);
    _frame = _engine.sample(0);
    // El ticker NO se para nunca mientras el widget este montado: BotEngine
    // ancla pulse() a _now (el t del ultimo sample()), y si el reloj se
    // parase ese _now quedaria obsoleto — el primer sample() tras un pulse()
    // veria t - _pulseStart >= 0.9 y descartaria el pulso al instante. El
    // control de coste se hace descartando frames en _onTick, no parando esto.
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Cadencia por mood: descartamos los frames que llegan demasiado pronto.
    // El t que le pasamos a sample() sigue siendo el tiempo real transcurrido,
    // sin cuantizar ni acumular, o las animaciones cambiarian de velocidad
    // segun el mood.
    final fps = BotEngine.fpsFor(_engine.effectiveMood);
    final intervalo = Duration(microseconds: (1000000 / fps).round());
    if (elapsed - _ultimoPintado < intervalo) return;
    _ultimoPintado = elapsed;

    final f = _engine.sample(elapsed.inMicroseconds / 1000000.0);
    if (f != _frame) setState(() => _frame = f);
  }

  @override
  void didUpdateWidget(BotAvatar old) {
    super.didUpdateWidget(old);
    if (widget.mood != old.mood) _engine.hold(widget.mood);
    if (widget.pulseToken != null &&
        widget.pulseToken != old.pulseToken &&
        widget.pulseMood != null) {
      _engine.pulse(widget.pulseMood!);
    }
    if (widget.gazeToken != null && widget.gazeToken != old.gazeToken) {
      _engine.setGaze(widget.gazeDx, widget.gazeDy);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: BotPainter(
          frame: _frame,
          bodyColor: widget.bodyColor,
          eyeColor: widget.eyeColor,
        ),
      ),
    );
  }
}
