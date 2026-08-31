//
// Motor de animacion del bot. Constantes de pose y timing portadas de Bloub
// (https://github.com/jeremy-prt/bloub) — MIT, (c) jeremy-prt.
// Ver THIRD_PARTY_NOTICES.md.
//
// NO importar el binding de UI de Flutter aqui: este fichero se testea como
// Dart plano y esa restriccion es lo que lo mantiene barato de testear.
import 'dart:math' as math;

import '../data/bot_profiles.dart';
import 'bot_eyes.dart';
import 'bot_frame.dart';
import 'bot_math.dart';
import 'bot_mood.dart';

// --- Constantes portadas de Bloub -----------------------------------------
const double _blinkDur = 0.18;        // face.ts:131
const List<double> _dotX = [-0.557, -0.013, 0.532]; // decor.ts:203
const double _dotR = 0.165;           // decor.ts:204
const double _dotPeak = 1.25;         // decor.ts:205
const double _sleepR = 0.1585;        // states.ts:370
const double _sleepCy = 0.11;
const double _sleepAmp = 0.19;
const double _sleepPeriod = 0.6;

class BotEngine {
  BotMood _sustained = BotMood.idle;
  BotMood? _pulse;
  double _pulseStart = 0;
  double _now = 0;

  static const double _pulseDuration = 0.9;

  static int fpsFor(BotMood m) {
    switch (m) {
      case BotMood.idle:
        return 15;
      case BotMood.sleeping:
        return 30;
      case BotMood.thinking:
      case BotMood.pleased:
      case BotMood.surprised:
        return 60;
    }
  }

  void hold(BotMood m) {
    if (m.isTransient) return;
    if (m == _sustained) return;
    _sustained = m;
    _pulse = null;
  }

  void pulse(BotMood m) {
    if (!m.isTransient) return;
    if (_sustained != BotMood.idle) return;
    _pulse = m;
    _pulseStart = _now;
  }

  BotMood get effectiveMood {
    if (_sustained != BotMood.idle) return _sustained;
    return _pulse ?? BotMood.idle;
  }

  bool get isSettled => _pulse == null;

  BotFrame sample(double t) {
    _now = t;
    if (_pulse != null && t - _pulseStart >= _pulseDuration) _pulse = null;

    switch (effectiveMood) {
      case BotMood.thinking:
        return _thinking(t);
      case BotMood.sleeping:
        return _sleeping(t);
      case BotMood.pleased:
        return _pleased(t, clamp01((t - _pulseStart) / _pulseDuration));
      case BotMood.surprised:
        return _surprised(t, clamp01((t - _pulseStart) / _pulseDuration));
      case BotMood.idle:
        return _idle(t);
    }
  }

  // --- Poses ---------------------------------------------------------------

  /// 1 = ojo abierto, 0 = cerrado.
  ///
  /// Bloub sortea los instantes de parpadeo con un RNG sembrado; aqui basta un
  /// horario deterministico de periodo 3.25s (el centro del rango 1.9-4.6 de
  /// face.ts), porque `sample(t)` tiene que ser funcion pura del tiempo.
  double _lid(double t) {
    const periodo = 3.25;
    final fase = t % periodo;
    if (fase > _blinkDur) return 1;
    return (1 - math.cos((fase / _blinkDur) * tau)) / 2;
  }

  List<EyeSpec> _eyes({double lid = 1, double scale = 1, double wink = 1}) {
    final l = kRestEyes[0], r = kRestEyes[1];
    return [
      EyeSpec(cx: l.cx, cy: l.cy, rx: l.rx * scale, ry: l.ry * lid * scale,
          a: l.a, b: l.b, c: l.c, d: l.d),
      EyeSpec(cx: r.cx, cy: r.cy, rx: r.rx * scale, ry: r.ry * lid * wink * scale,
          a: r.a, b: r.b, c: r.c, d: r.d),
    ];
  }

  BotFrame _body({
    required double t,
    double r = 1,
    double cy = 0,
    double sx = 1,
    double sy = 1,
    double bodyAlpha = 1,
    List<EyeSpec> eyes = const [],
    List<DotSpec> dots = const [],
  }) {
    return BotFrame(
      radii: r == 1 ? kSphereProfile : kSphereProfile.map((v) => v * r).toList(),
      rot: 0,
      cx: 0,
      cy: cy,
      sx: sx,
      sy: sy,
      bodyAlpha: bodyAlpha,
      eyes: eyes,
      dots: dots,
    );
  }

  /// Respiracion suave sobre la bola en reposo.
  BotFrame _idle(double t) {
    final respira = math.sin(t * tau / 2.4) * 0.02; // duracion idle de Bloub
    return _body(
      t: t,
      sx: 1 + respira,
      sy: 1 - respira,
      eyes: _eyes(lid: _lid(t)),
    );
  }

  /// Pulso de los tres puntos. Port directo de dotPulse (states.ts:200).
  double _dotPulse(double t, int index) {
    var p = ((t - index * 0.5) / 1.5) % 1;
    if (p < 0) p += 1;
    final k = p < 0.5 ? 0.5 - 0.5 * math.cos(p * tau) : 0.0;
    return clamp01(k * 2);
  }

  BotFrame _thinking(double t) {
    final puntos = List<DotSpec>.generate(3, (i) {
      final pulso = _dotPulse(t, i);
      return DotSpec(
        cx: _dotX[i],
        cy: 0,
        r: _dotR * (1 + (_dotPeak - 1) * pulso),
        alpha: lerpD(0.55, 1.0, pulso),
      );
    });
    return _body(t: t, bodyAlpha: 0, dots: puntos);
  }

  /// Guino: el ojo exterior se cierra y se abre una vez.
  BotFrame _pleased(double t, double p) {
    final cierre = math.sin(clamp01(p) * math.pi);
    return _body(t: t, eyes: _eyes(wink: 1 - cierre * 0.92));
  }

  /// Sorpresa: ojos mas grandes y un empujon de escala que se relaja.
  BotFrame _surprised(double t, double p) {
    final golpe = math.sin(clamp01(p) * math.pi);
    final escala = 1 + 0.06 * golpe;
    return _body(
      t: t,
      sx: escala,
      sy: escala,
      eyes: _eyes(scale: 1 + 0.22 * golpe),
    );
  }

  /// Bolita rebotando, ojos cerrados. Constantes de states.ts:370.
  BotFrame _sleeping(double t) {
    final rebote = math.sin(t * tau / _sleepPeriod) * _sleepAmp;
    return _body(
      t: t,
      sx: _sleepR,
      sy: _sleepR,
      cy: _sleepCy + rebote,
      eyes: _eyes(lid: 0.08),
    );
  }
}
