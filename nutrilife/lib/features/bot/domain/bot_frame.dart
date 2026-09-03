//
// Portado de Bloub (https://github.com/jeremy-prt/bloub) — MIT, (c) jeremy-prt.
// Ver THIRD_PARTY_NOTICES.md.

class EyeSpec {
  final double cx, cy, rx, ry, alpha;

  /// Matriz tangente 2x2 de la orientacion del ojo sobre la esfera:
  /// pantalla = u*(a,b) + v*(c,d). Default identidad (ojo plano, sin
  /// inclinacion) para no romper a quien construya un EyeSpec sin orientacion.
  final double a, b, c, d;

  /// Offset de mirada en unidades del radio de la bola (espacio normalizado
  /// del bot). Lo calcula el motor en `BotEngine._eyes()` a partir del
  /// ultimo setGaze() y el reloj de sample(); el painter lo aplica como
  /// `cx * r0 + gazeDx * r0`. Default 0 = mirada al frente de reposo.
  final double gazeDx, gazeDy;

  const EyeSpec({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    this.alpha = 1,
    this.a = 1,
    this.b = 0,
    this.c = 0,
    this.d = 1,
    this.gazeDx = 0,
    this.gazeDy = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is EyeSpec &&
      other.cx == cx && other.cy == cy &&
      other.rx == rx && other.ry == ry && other.alpha == alpha &&
      other.a == a && other.b == b && other.c == c && other.d == d &&
      other.gazeDx == gazeDx && other.gazeDy == gazeDy;

  @override
  int get hashCode =>
      Object.hash(cx, cy, rx, ry, alpha, a, b, c, d, gazeDx, gazeDy);
}

class DotSpec {
  final double cx, cy, r, alpha;
  const DotSpec({required this.cx, required this.cy, required this.r, this.alpha = 1});

  @override
  bool operator ==(Object other) =>
      other is DotSpec &&
      other.cx == cx && other.cy == cy && other.r == r && other.alpha == alpha;

  @override
  int get hashCode => Object.hash(cx, cy, r, alpha);
}

/// Un instante congelado del bot. Coordenadas normalizadas: el origen es el
/// centro del canvas y 1.0 es el radio del circulo inscrito.
class BotFrame {
  final List<double> radii;
  final double rot, cx, cy, sx, sy, bodyAlpha;
  final List<EyeSpec> eyes;
  final List<DotSpec> dots;

  const BotFrame({
    required this.radii,
    required this.rot,
    required this.cx,
    required this.cy,
    required this.sx,
    required this.sy,
    required this.bodyAlpha,
    required this.eyes,
    required this.dots,
  });

  @override
  bool operator ==(Object other) {
    if (other is! BotFrame) return false;
    if (other.rot != rot || other.cx != cx || other.cy != cy) return false;
    if (other.sx != sx || other.sy != sy || other.bodyAlpha != bodyAlpha) return false;
    if (other.radii.length != radii.length) return false;
    for (var i = 0; i < radii.length; i++) {
      if (other.radii[i] != radii[i]) return false;
    }
    return _listEq(other.eyes, eyes) && _listEq(other.dots, dots);
  }

  static bool _listEq(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(radii), rot, cx, cy, sx, sy, bodyAlpha,
        Object.hashAll(eyes), Object.hashAll(dots),
      );
}
