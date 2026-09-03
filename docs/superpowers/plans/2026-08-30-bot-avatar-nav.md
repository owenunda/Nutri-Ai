# Avatar animado (blob Bloub) en el botón IA — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sustituir el icono estático del botón central "IA" de la nav bar por un blob animado que reacciona al estado real del chat.

**Architecture:** Un motor puro en Dart (`sample(t) -> BotFrame`, sin `dart:ui`) alimentado por perfiles radiales de 64 radios portados de Bloub; un `CustomPainter` que convierte esos radios en un `Path` con splines Catmull-Rom; y un `ChangeNotifier` singleton que lleva el mood desde el chat hasta la nav bar, siguiendo el patrón que el proyecto ya usa en `DioClient.rateLimit`.

**Tech Stack:** Flutter/Dart puro. **Cero dependencias nuevas.**

**Spec:** `docs/superpowers/specs/2026-08-30-bot-avatar-nav-design.md`

## Global Constraints

- **No añadir dependencias a `pubspec.yaml`.** Nada de `path_drawing`, `provider`, `rive`, `lottie`.
- **`bot_engine.dart`, `bot_frame.dart`, `bot_mood.dart` y `bot_math.dart` NO pueden importar `dart:ui` ni `package:flutter/*`.** Solo `dart:math`. Esto es lo que mantiene el motor testeable como Dart plano.
- Todas las rutas son relativas a `nutriapp/`. Los comandos se ejecutan desde `nutriapp/`.
- Los radios se guardan **normalizados** (0..1, donde 1 = radio del círculo que encaja en el canvas). El painter los escala.
- `PROFILE_SAMPLES = 64` en todas las formas, sin excepción.
- Colores del blob: cuerpo `#FFFFFF`, ojos `#134E32`. El círculo con gradiente `#0A6B3F → #1E56F5` del botón no se toca.
- Bloub es MIT: todo archivo con dato o matemática portada lleva cabecera de atribución.
- Comentarios y mensajes de commit en español, como el resto del repo.

## File Structure

| Archivo | Responsabilidad |
|---|---|
| `lib/features/bot/domain/bot_mood.dart` | El enum y la distinción transitorio/sostenido |
| `lib/features/bot/domain/bot_frame.dart` | `BotFrame`, `EyeSpec`, `DotSpec` — valores inmutables con `==` |
| `lib/features/bot/domain/bot_math.dart` | lerp, lerp angular por camino corto, easing, blend de radios |
| `lib/features/bot/data/bot_profiles.dart` | Constantes de radios portadas de Bloub |
| `lib/features/bot/domain/bot_engine.dart` | Moods, precedencia, poses, `sample(t)` |
| `lib/features/bot/presentation/bot_path.dart` | Catmull-Rom: radios → `Path` |
| `lib/features/bot/presentation/bot_painter.dart` | `BotFrame` → `Canvas` |
| `lib/features/bot/presentation/bot_avatar.dart` | Widget con `Ticker` y cadencia por mood |
| `lib/core/state/bot_mood_state.dart` | Singleton compartido chat ↔ nav bar |
| `tool/extract_bloub_profiles.dart` | Script de un solo uso |

**Orden de dependencias:** estrictamente secuencial. Tasks 1-2 no dependen de nada; de la 3 en adelante cada una consume lo que produjo la anterior.

**Nota sobre el dato portado:** el plan original preveía un script que extrajera perfiles radiales del fuente de Bloub. Al leer el código resultó que los cinco estados que portamos usan **círculos**, no perfiles medidos: los únicos perfiles radiales reales de Bloub (`egg`, `hexagon`, `triangle`) son justo los que el spec excluye. Lo que sí se porta son las constantes de pose y timing de `face.ts`, `decor.ts` y `states.ts`, que están tabuladas dentro de la Task 3.

---

### Task 1: Tipos base (`BotMood`, `BotFrame`)

**Files:**
- Create: `lib/features/bot/domain/bot_mood.dart`
- Create: `lib/features/bot/domain/bot_frame.dart`
- Test: `test/features/bot/bot_frame_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `enum BotMood { idle, thinking, pleased, surprised, sleeping }`, `bool BotMood.isTransient`, `class EyeSpec`, `class DotSpec`, `class BotFrame`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/bot/bot_frame_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_frame.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

void main() {
  test('pleased y surprised son transitorios; el resto sostenidos', () {
    expect(BotMood.pleased.isTransient, isTrue);
    expect(BotMood.surprised.isTransient, isTrue);
    expect(BotMood.idle.isTransient, isFalse);
    expect(BotMood.thinking.isTransient, isFalse);
    expect(BotMood.sleeping.isTransient, isFalse);
  });

  test('dos BotFrame con los mismos valores son iguales', () {
    BotFrame make() => BotFrame(
          radii: const [1.0, 1.0, 1.0, 1.0],
          rot: 0.5,
          cx: 0,
          cy: 0,
          sx: 1,
          sy: 1,
          bodyAlpha: 1,
          eyes: const [EyeSpec(cx: -0.2, cy: 0, rx: 0.07, ry: 0.17)],
          dots: const [],
        );
    expect(make(), equals(make()));
    expect(make().hashCode, equals(make().hashCode));
  });

  test('un BotFrame con distinto bodyAlpha no es igual', () {
    const a = BotFrame(radii: [1.0], rot: 0, cx: 0, cy: 0, sx: 1, sy: 1, bodyAlpha: 1, eyes: [], dots: []);
    const b = BotFrame(radii: [1.0], rot: 0, cx: 0, cy: 0, sx: 1, sy: 1, bodyAlpha: 0.5, eyes: [], dots: []);
    expect(a, isNot(equals(b)));
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/bot/bot_frame_test.dart`
Expected: FAIL — "Target of URI doesn't exist: 'package:nutriapp/features/bot/domain/bot_frame.dart'"

- [ ] **Step 3: Implementar los tipos**

```dart
// lib/features/bot/domain/bot_mood.dart
enum BotMood { idle, thinking, pleased, surprised, sleeping }

extension BotMoodX on BotMood {
  /// Los transitorios se disparan con pulse() y vuelven solos a idle.
  bool get isTransient => this == BotMood.pleased || this == BotMood.surprised;
}
```

```dart
// lib/features/bot/domain/bot_frame.dart
//
// Portado de Bloub (https://github.com/jeremy-prt/bloub) — MIT, (c) jeremy-prt.
// Ver THIRD_PARTY_NOTICES.md.

class EyeSpec {
  final double cx, cy, rx, ry, alpha;
  const EyeSpec({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    this.alpha = 1,
  });

  @override
  bool operator ==(Object other) =>
      other is EyeSpec &&
      other.cx == cx && other.cy == cy &&
      other.rx == rx && other.ry == ry && other.alpha == alpha;

  @override
  int get hashCode => Object.hash(cx, cy, rx, ry, alpha);
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
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/bot/bot_frame_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/bot/domain/bot_mood.dart lib/features/bot/domain/bot_frame.dart test/features/bot/bot_frame_test.dart
git commit -m "feat(bot): tipos base BotMood y BotFrame"
```

---

### Task 2: Matemática del morphing

**Files:**
- Create: `lib/features/bot/domain/bot_math.dart`
- Test: `test/features/bot/bot_math_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `double lerpD(double a, double b, double t)`, `double lerpAngle(double a, double b, double t)`, `double easeOutQuint(double t)`, `double clamp01(double v)`, `List<double> blendRadii(List<double> a, List<double> b, double t)`.

- [ ] **Step 1: Escribir el test que falla**

El caso que importa de verdad es el ángulo: de 350° a 10° debe pasar por 0°, no dar la vuelta larga.

```dart
// test/features/bot/bot_math_test.dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_math.dart';

const tau = 2 * math.pi;
double deg(double d) => d * math.pi / 180;

void main() {
  test('lerpD interpola linealmente y clava los extremos', () {
    expect(lerpD(10, 20, 0), equals(10));
    expect(lerpD(10, 20, 1), equals(20));
    expect(lerpD(10, 20, 0.5), equals(15));
  });

  test('lerpAngle toma el camino corto de 350 a 10 grados', () {
    final mid = lerpAngle(deg(350), deg(10), 0.5) % tau;
    // El punto medio por el camino corto es 0 grados (o tau, equivalente).
    final dist = math.min(mid, tau - mid);
    expect(dist, lessThan(deg(0.001)));
  });

  test('lerpAngle toma el camino corto de 10 a 350 grados', () {
    final mid = lerpAngle(deg(10), deg(350), 0.5) % tau;
    final dist = math.min(mid, tau - mid);
    expect(dist, lessThan(deg(0.001)));
  });

  test('lerpAngle con t=0 y t=1 devuelve angulos equivalentes a los extremos', () {
    expect(lerpAngle(deg(350), deg(10), 0) % tau, closeTo(deg(350), 1e-9));
    expect(lerpAngle(deg(350), deg(10), 1) % tau, closeTo(deg(10), 1e-9));
  });

  test('easeOutQuint arranca en 0, acaba en 1 y va por delante de la recta', () {
    expect(easeOutQuint(0), closeTo(0, 1e-9));
    expect(easeOutQuint(1), closeTo(1, 1e-9));
    expect(easeOutQuint(0.5), greaterThan(0.5));
  });

  test('clamp01 recorta fuera de rango', () {
    expect(clamp01(-3), equals(0));
    expect(clamp01(0.4), equals(0.4));
    expect(clamp01(9), equals(1));
  });

  test('blendRadii clava los extremos e interpola cada indice', () {
    final a = [1.0, 2.0, 3.0];
    final b = [3.0, 2.0, 1.0];
    expect(blendRadii(a, b, 0), equals(a));
    expect(blendRadii(a, b, 1), equals(b));
    expect(blendRadii(a, b, 0.5), equals([2.0, 2.0, 2.0]));
  });

  test('blendRadii revienta si las longitudes no coinciden', () {
    expect(() => blendRadii([1.0], [1.0, 2.0], 0.5), throwsArgumentError);
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/bot/bot_math_test.dart`
Expected: FAIL — el fichero `bot_math.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/bot/domain/bot_math.dart
//
// Matematica portada de Bloub (https://github.com/jeremy-prt/bloub) — MIT,
// (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;

const double tau = 2 * math.pi;

double lerpD(double a, double b, double t) => a + (b - a) * t;

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double easeOutQuint(double t) {
  final u = 1 - clamp01(t);
  return 1 - u * u * u * u * u;
}

/// Interpola angulos por el camino corto: de 350 a 10 grados pasa por 0,
/// no da la vuelta de 340 grados.
double lerpAngle(double a, double b, double t) {
  // En Dart, x % tau siempre cae en [0, tau) aunque x sea negativo.
  var d = (b - a) % tau;
  if (d > math.pi) d -= tau; // ahora en (-pi, pi]
  return a + d * t;
}

List<double> blendRadii(List<double> a, List<double> b, double t) {
  if (a.length != b.length) {
    throw ArgumentError('perfiles de distinta longitud: ${a.length} vs ${b.length}');
  }
  return List<double>.generate(a.length, (i) => lerpD(a[i], b[i], t), growable: false);
}
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/bot/bot_math_test.dart`
Expected: PASS (8 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/bot/domain/bot_math.dart test/features/bot/bot_math_test.dart
git commit -m "feat(bot): matematica de morphing con lerp angular por camino corto"
```

---

### Task 3: El motor, con las constantes reales de Bloub

Esta task funde la antigua Task 3 (extracción de perfiles) con la Task 4 (motor). Motivo: al leer el fuente de Bloub resultó que **no hay perfiles radiales que extraer** para nuestros cinco estados — todos usan círculos. Lo que sí hay que portar son las constantes de pose y timing.

**Files:**
- Create: `lib/features/bot/data/bot_profiles.dart`
- Create: `lib/features/bot/domain/bot_eyes.dart`
- Create: `lib/features/bot/domain/bot_engine.dart`
- Modify: `lib/features/bot/domain/bot_frame.dart` (añadir la matriz a `EyeSpec`)
- Create: `THIRD_PARTY_NOTICES.md` (raíz del repo, fuera de `nutriapp/`)
- Test: `test/features/bot/bot_engine_test.dart`
- Test: `test/features/bot/bot_eyes_test.dart`

**Interfaces:**
- Consumes: `BotMood`, `BotFrame`, `EyeSpec`, `DotSpec` (Task 1); `lerpD`, `lerpAngle`, `easeOutQuint`, `clamp01`, `blendRadii` (Task 2).
- Produces: `const int kProfileSamples = 64`, `final List<double> kSphereProfile`; `const List<EyeSpec> kRestEyes`; `class BotEngine` con `void hold(BotMood)`, `void pulse(BotMood)`, `BotMood get effectiveMood`, `bool get isSettled`, `BotFrame sample(double t)`, `static int fpsFor(BotMood)`.

#### Por qué no hay perfiles que extraer

Verificado leyendo el fuente:

- Los radios viven en `src/bot/profiles.ts`, no en `shape.ts`.
- `PROFILES` contiene solo `egg`, `hexagon` y `triangle` — **no hay `sphere`**.
- `base()` en `states.ts:73` hace `sil: circle(1)`. Los estados `idle`, `wink` y `wide` usan `base()`. `thinking` usa `circle(DOT_R * …)`. `sleep` usa `circle(0.1585, …)`.
- Las tres formas radiales que sí existen son exactamente las que el spec excluye.

Conclusión: `kSphereProfile` son 64 radios a 1.0, generados en Dart. No hay script extractor.

#### Constantes portadas de Bloub (valores literales, medidos del vídeo original)

| Constante | Valor | Origen |
|---|---|---|
| `PROFILE_SAMPLES` | 64 | `profiles.ts` |
| `EYE_W` | 0.186 | `face.ts:23` |
| `EYE_H` | 0.412 | `face.ts:24` |
| `EYE_SPLIT` | 15.46 (grados) | `face.ts:21` |
| `REST_GAZE` | yaw 28.49, pitch 28.62, roll −13 | `face.ts:27` |
| `BLINK_DUR` | 0.18 s | `face.ts:131` |
| intervalo de parpadeo | 1.9 + rnd·2.7 s | `face.ts:121` |
| `DOT_X` | −0.557, −0.013, 0.532 | `decor.ts:203` |
| `DOT_R` | 0.165 | `decor.ts:204` |
| `DOT_PEAK` | 1.25 | `decor.ts:205` |
| `sleep` | `circle(0.1585, cy: 0.11 + sin(t·TAU/0.6)·0.19)` | `states.ts:370` |
| duración `idle` / morph | 2.4 / 0.45 | `states.ts:209-210` |
| duración `thinking` / morph | 2.6 / 0.4 | `states.ts:219-220` |

Todo en unidades de radio de la bola (1.0 = radio en reposo).

- [ ] **Step 1: Escribir `bot_profiles.dart` y el aviso de terceros**

```dart
// lib/features/bot/data/bot_profiles.dart
//
// Constantes portadas de Bloub (https://github.com/jeremy-prt/bloub)
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.

/// PROFILE_SAMPLES en Bloub (profiles.ts).
const int kProfileSamples = 64;

/// La bola en reposo. En Bloub el cuerpo de idle/wink/wide/thinking/sleep sale
/// de `circle(r)`, que rellena los 64 radios con el mismo valor: no es un
/// perfil medido, es un circulo. Los unicos perfiles radiales reales de Bloub
/// (egg, hexagon, triangle) quedan fuera del alcance de esta feature.
final List<double> kSphereProfile = List<double>.unmodifiable(
  List<double>.filled(kProfileSamples, 1.0),
);
```

Y crea `THIRD_PARTY_NOTICES.md` en la **raíz del repo** (un nivel por encima de `nutriapp/`). Copia el texto de la licencia literalmente desde el `LICENSE` del clon de Bloub que se te indica en el dispatch; no lo escribas de memoria. El fichero debe decir qué se portó: la técnica (perfiles radiales muestreados + Catmull-Rom con tensión 1/6) y las constantes de pose y timing medidas, no arrays de datos.

- [ ] **Step 2: Escribir el test de los ojos**

Como en nuestros cinco estados la mirada nunca cambia (todos usan `REST_GAZE`), las dos poses de ojo son **constantes**: se calculan una vez al arrancar, no por frame.

```dart
// test/features/bot/bot_eyes_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_eyes.dart';

void main() {
  test('hay exactamente dos ojos', () {
    expect(kRestEyes.length, equals(2));
  });

  test('los dos ojos estan dentro de la bola', () {
    for (final e in kRestEyes) {
      final d = e.cx * e.cx + e.cy * e.cy;
      expect(d, lessThan(1.0), reason: 'ojo fuera de la esfera unidad');
    }
  });

  test('los ojos estan separados horizontalmente', () {
    expect((kRestEyes[0].cx - kRestEyes[1].cx).abs(), greaterThan(0.15));
  });

  test('la matriz de cada ojo no es degenerada', () {
    for (final e in kRestEyes) {
      final det = e.a * e.d - e.c * e.b;
      expect(det.abs(), greaterThan(0.01), reason: 'matriz degenerada: el ojo colapsa');
    }
  });

  test('las dimensiones son las medidas de Bloub', () {
    for (final e in kRestEyes) {
      expect(e.rx, closeTo(0.186 / 2, 1e-9));
      expect(e.ry, closeTo(0.412 / 2, 1e-9));
    }
  });
}
```

- [ ] **Step 3: Ejecutar y verificar que falla**

Run: `flutter test test/features/bot/bot_eyes_test.dart`
Expected: FAIL — `bot_eyes.dart` no existe.

- [ ] **Step 4: Añadir la matriz a `EyeSpec`**

`EyeSpec` (Task 1) tiene `cx, cy, rx, ry, alpha`. Añádele cuatro campos con default identidad, y mételos en `==` y en `hashCode`:

```dart
  final double a, b, c, d; // matriz 2x2: pantalla = u*(a,b) + v*(c,d)
```

Constructor: `this.a = 1, this.b = 0, this.c = 0, this.d = 1`. Los tests existentes de `bot_frame_test.dart` deben seguir pasando sin tocarlos.

- [ ] **Step 5: Portar `eyePoses` y calcular las poses en reposo**

Port directo de `face.ts`. `spin` gira dos vectores 3D uno hacia el otro; la cámara mira con x a la derecha, y hacia abajo, z hacia el espectador.

```dart
// lib/features/bot/domain/bot_eyes.dart
//
// Portado de face.ts de Bloub (https://github.com/jeremy-prt/bloub)
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;

import 'bot_frame.dart';

const double kEyeW = 0.186;
const double kEyeH = 0.412;
const double kEyeSplit = 15.46; // grados
const double kGazeYaw = 28.49;
const double kGazePitch = 28.62;
const double kGazeRoll = -13;

double _deg(double d) => d * math.pi / 180;

/// Gira `u` hacia `v` por `angle`. Devuelve los dos vectores girados.
List<List<double>> _spin(List<double> u, List<double> v, double angle) {
  final c = math.cos(angle), s = math.sin(angle);
  return [
    [u[0] * c + v[0] * s, u[1] * c + v[1] * s, u[2] * c + v[2] * s],
    [v[0] * c - u[0] * s, v[1] * c - u[1] * s, v[2] * c - u[2] * s],
  ];
}

List<EyeSpec> _computeRestEyes() {
  var f = <double>[0, 0, 1];
  var right = <double>[1, 0, 0];
  var down = <double>[0, 1, 0];

  var r = _spin(f, right, _deg(kGazeYaw));
  f = r[0];
  right = r[1];

  r = _spin(down, f, _deg(kGazePitch));
  down = r[0];
  f = r[1];

  r = _spin(right, down, _deg(kGazeRoll));
  right = r[0];
  down = r[1];

  EyeSpec build(double side) {
    final e = _spin(f, right, _deg(kEyeSplit * side));
    final ef = e[0], er = e[1];
    return EyeSpec(
      cx: ef[0],
      cy: ef[1],
      rx: kEyeW / 2,
      ry: kEyeH / 2,
      a: er[0],
      b: er[1],
      c: down[0],
      d: down[1],
    );
  }

  return List<EyeSpec>.unmodifiable([build(-1), build(1)]);
}

/// Las dos poses de ojo en reposo. Constantes: en los cinco estados portados
/// la mirada nunca cambia, asi que no hace falta recalcularlas por frame.
final List<EyeSpec> kRestEyes = _computeRestEyes();
```

- [ ] **Step 6: Ejecutar y verificar que pasan**

Run: `flutter test test/features/bot/bot_eyes_test.dart test/features/bot/bot_frame_test.dart`
Expected: PASS. Si el test "los dos ojos estan dentro de la bola" falla, revisa el orden de las tres rotaciones en `_computeRestEyes` — es el error más probable.

- [ ] **Step 7: Escribir el test del motor**

```dart
// test/features/bot/bot_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_engine.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

void main() {
  test('arranca en idle y asentado', () {
    final e = BotEngine();
    expect(e.effectiveMood, equals(BotMood.idle));
    expect(e.isSettled, isTrue);
  });

  test('sample es determinista para el mismo t', () {
    final e = BotEngine();
    expect(e.sample(1.234), equals(e.sample(1.234)));
  });

  test('sample devuelve kProfileSamples radios', () {
    final e = BotEngine();
    expect(e.sample(0).radii.length, equals(64));
  });

  test('idle muestra el cuerpo y dos ojos, sin puntos', () {
    final e = BotEngine();
    final f = e.sample(2.0);
    expect(f.bodyAlpha, greaterThan(0.95));
    expect(f.eyes.length, equals(2));
    expect(f.dots, isEmpty);
  });

  test('idle parpadea en algun momento de los primeros 10 segundos', () {
    final e = BotEngine();
    var vioCerrado = false;
    for (var i = 0; i < 1000; i++) {
      final f = e.sample(i * 0.01);
      if (f.eyes.isNotEmpty && f.eyes[0].ry < kRestEyes[0].ry * 0.5) {
        vioCerrado = true;
        break;
      }
    }
    expect(vioCerrado, isTrue, reason: 'no parpadeo nunca');
  });

  test('thinking oculta el cuerpo y muestra tres puntos', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    expect(f.bodyAlpha, lessThan(0.05));
    expect(f.dots.length, equals(3));
    expect(f.eyes, isEmpty);
  });

  test('los tres puntos estan en las posiciones medidas de Bloub', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    expect(f.dots[0].cx, closeTo(-0.557, 1e-9));
    expect(f.dots[1].cx, closeTo(-0.013, 1e-9));
    expect(f.dots[2].cx, closeTo(0.532, 1e-9));
  });

  test('los puntos pulsan desfasados: no todos tienen el mismo radio', () {
    final e = BotEngine()..hold(BotMood.thinking);
    final f = e.sample(2.0);
    final radios = f.dots.map((d) => d.r).toSet();
    expect(radios.length, greaterThan(1));
  });

  test('sleeping encoge la bola y la hace rebotar', () {
    final e = BotEngine()..hold(BotMood.sleeping);
    final a = e.sample(2.0);
    final b = e.sample(2.3);
    expect(a.sx, closeTo(0.1585, 1e-9));
    expect(a.cy, isNot(closeTo(b.cy, 1e-6)), reason: 'no rebota');
  });

  test('PRECEDENCIA: sleeping gana sobre thinking', () {
    final e = BotEngine()
      ..hold(BotMood.thinking)
      ..hold(BotMood.sleeping);
    expect(e.effectiveMood, equals(BotMood.sleeping));
  });

  test('PRECEDENCIA: un pulse durante thinking no interrumpe el pensar', () {
    final e = BotEngine()..hold(BotMood.thinking);
    e.pulse(BotMood.pleased);
    expect(e.effectiveMood, equals(BotMood.thinking));
  });

  test('un pulse sobre idle si se aplica', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    expect(e.effectiveMood, equals(BotMood.pleased));
    expect(e.isSettled, isFalse);
  });

  test('un pulse termina solo y vuelve a idle', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    e.sample(5.0);
    expect(e.effectiveMood, equals(BotMood.idle));
    expect(e.isSettled, isTrue);
  });

  test('pleased cierra un ojo y deja el otro abierto', () {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    final f = e.sample(0.45); // mitad del pulse
    expect(f.eyes[1].ry, lessThan(f.eyes[0].ry * 0.5));
  });

  test('fpsFor declara cadencia reducida en idle y plena en thinking', () {
    expect(BotEngine.fpsFor(BotMood.idle), equals(15));
    expect(BotEngine.fpsFor(BotMood.thinking), equals(60));
    expect(BotEngine.fpsFor(BotMood.pleased), equals(60));
    expect(BotEngine.fpsFor(BotMood.sleeping), equals(30));
  });
}
```

Añade el import de `bot_eyes.dart` al test para poder usar `kRestEyes`.

- [ ] **Step 8: Ejecutar y verificar que falla**

Run: `flutter test test/features/bot/bot_engine_test.dart`
Expected: FAIL — `bot_engine.dart` no existe.

- [ ] **Step 9: Implementar el motor**

Puntos clave: `sample(t)` es una función pura del tiempo; el parpadeo usa un horario determinista (nada de `Random` sin semilla, o `sample` dejaría de ser determinista y su test fallaría de forma intermitente).

```dart
// lib/features/bot/domain/bot_engine.dart
//
// Motor de animacion del bot. Constantes de pose y timing portadas de Bloub
// (https://github.com/jeremy-prt/bloub) — MIT, (c) jeremy-prt.
// Ver THIRD_PARTY_NOTICES.md.
//
// NO importar dart:ui ni package:flutter aqui: este fichero se testea como
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
    // (1 + cos) y NO (1 - cos): tiene que dar 1 en fase=0, 0 en el centro y 1
    // al final, para empalmar de forma continua con el `return 1` de arriba.
    // Con (1 - cos) el ojo sale cerrado en los bordes y abierto en el centro,
    // que es justo al reves, y ademas mete dos saltos duros.
    return (1 + math.cos((fase / _blinkDur) * tau)) / 2;
  }

  /// Suelo de altura del ojo (face.ts:177): sin el, `ry` llega a 0 exacto en el
  /// instante de cierre y la capsula degenera.
  double _blinkScale(double lid) => 0.06 + 0.94 * lid;

  List<EyeSpec> _eyes({double lid = 1, double scale = 1, double wink = 1}) {
    final l = kRestEyes[0], r = kRestEyes[1];
    lid = _blinkScale(lid);
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
    // face.ts:167. El ancho NO varia en Bloub: solo respira la altura, y muy
    // poco. Ojo: 2.4 es la `duration` del estado idle (states.ts:209), otra
    // magnitud distinta — no la uses como periodo de respiracion.
    final respira = math.sin(t * tau / 3.4) * 0.005;
    return _body(
      t: t,
      sy: 1 + respira,
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
```

- [ ] **Step 10: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/bot/`
Expected: PASS (todos los ficheros de bot).

- [ ] **Step 11: Verificar que el motor no arrastra Flutter**

Run: `grep -rn "dart:ui\|package:flutter" lib/features/bot/domain/ lib/features/bot/data/`
Expected: sin resultados. Si aparece alguno, el motor dejó de ser Dart plano — arréglalo antes de commitear.

- [ ] **Step 12: Commit**

```bash
git add lib/features/bot/ test/features/bot/ ../THIRD_PARTY_NOTICES.md
git commit -m "feat(bot): motor de animacion con las constantes medidas de Bloub"
```

---


### Task 4: Radios → Path (Catmull-Rom)

**Files:**
- Create: `lib/features/bot/presentation/bot_path.dart`
- Test: `test/features/bot/bot_path_test.dart`

**Interfaces:**
- Consumes: `BotFrame` (Task 1).
- Produces: `List<Offset> profilePoints(BotFrame f, Size size)`, `Path closedCatmullRomPath(List<Offset> pts)`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/bot/bot_path_test.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_frame.dart';
import 'package:nutriapp/features/bot/presentation/bot_path.dart';

BotFrame circulo({double sx = 1, double sy = 1, double cx = 0, double cy = 0}) => BotFrame(
      radii: List<double>.filled(64, 1.0),
      rot: 0,
      cx: cx,
      cy: cy,
      sx: sx,
      sy: sy,
      bodyAlpha: 1,
      eyes: const [],
      dots: const [],
    );

void main() {
  const size = Size(100, 100);

  test('un perfil de radios constantes cae sobre un circulo centrado', () {
    final pts = profilePoints(circulo(), size);
    expect(pts.length, equals(64));
    for (final p in pts) {
      final d = (p - const Offset(50, 50)).distance;
      expect(d, closeTo(50, 0.001));
    }
  });

  test('cx desplaza el centro en unidades de radio', () {
    final pts = profilePoints(circulo(cx: 0.5), size);
    final centro = pts.reduce((a, b) => a + b) / 64.0;
    expect(centro.dx, closeTo(50 + 25, 0.5));
    expect(centro.dy, closeTo(50, 0.5));
  });

  test('sy aplasta verticalmente', () {
    final pts = profilePoints(circulo(sy: 0.5), size);
    final maxY = pts.map((p) => p.dy).reduce(math.max);
    expect(maxY - 50, closeTo(25, 0.001));
  });

  test('el path cerrado sobre un circulo tiene un bounding box del tamano esperado', () {
    final path = closedCatmullRomPath(profilePoints(circulo(), size));
    final b = path.getBounds();
    expect(b.width, closeTo(100, 1.0));
    expect(b.height, closeTo(100, 1.0));
  });

  test('el path contiene el centro y excluye una esquina', () {
    final path = closedCatmullRomPath(profilePoints(circulo(), size));
    expect(path.contains(const Offset(50, 50)), isTrue);
    expect(path.contains(const Offset(2, 2)), isFalse);
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/bot/bot_path_test.dart`
Expected: FAIL — `bot_path.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/bot/presentation/bot_path.dart
//
// Conversion de perfiles radiales a Path. La tecnica (Catmull-Rom sobre
// muestras radiales) viene de Bloub — https://github.com/jeremy-prt/bloub
// MIT, (c) jeremy-prt. Ver THIRD_PARTY_NOTICES.md.
import 'dart:math' as math;
import 'dart:ui';

import '../domain/bot_frame.dart';

/// Convierte los radios normalizados del frame en puntos de pantalla.
List<Offset> profilePoints(BotFrame f, Size size) {
  final n = f.radii.length;
  final r0 = size.shortestSide / 2;
  final ox = size.width / 2 + f.cx * r0;
  final oy = size.height / 2 + f.cy * r0;
  return List<Offset>.generate(n, (i) {
    final a = (i / n) * 2 * math.pi + f.rot;
    return Offset(
      ox + math.cos(a) * f.radii[i] * r0 * f.sx,
      oy + math.sin(a) * f.radii[i] * r0 * f.sy,
    );
  }, growable: false);
}

/// Spline Catmull-Rom cerrada, convertida a Bezier cubica.
///
/// Para cada segmento P1->P2, los puntos de control salen de los vecinos:
///   c1 = P1 + (P2 - P0) / 6
///   c2 = P2 - (P3 - P1) / 6
Path closedCatmullRomPath(List<Offset> pts) {
  final n = pts.length;
  final path = Path();
  if (n < 4) return path;

  path.moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/bot/bot_path_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/bot/presentation/bot_path.dart test/features/bot/bot_path_test.dart
git commit -m "feat(bot): convertir perfiles radiales a Path con Catmull-Rom"
```

---

### Task 5: El painter

**Files:**
- Create: `lib/features/bot/presentation/bot_painter.dart`
- Test: `test/features/bot/bot_painter_test.dart`
- Create: `test/features/bot/goldens/` (generado)

**Interfaces:**
- Consumes: `BotFrame` (Task 1), `BotEngine` (Task 3), `profilePoints` + `closedCatmullRomPath` (Task 4).
- Produces: `class BotPainter extends CustomPainter` con constructor `BotPainter({required BotFrame frame, required Color bodyColor, required Color eyeColor})`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/bot/bot_painter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_engine.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/bot/presentation/bot_painter.dart';

// Key propia: MaterialApp y Scaffold montan sus propios CustomPaint, asi que
// find.byType(CustomPaint).last no garantiza ser el nuestro.
const kBlobKey = ValueKey('blob-test');

Widget _caja(BotEngine e, double t) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A6B3F),
        body: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            // RepaintBoundary propio con la key: matchesGoldenFile captura el
            // PRIMER RenderRepaintBoundary ancestro, y ni CustomPaint ni
            // SizedBox ni Center lo son. Sin esto el golden sale de 800x600
            // (la superficie de test entera) con el blob perdido en medio.
            child: RepaintBoundary(
              key: kBlobKey,
              child: CustomPaint(
                painter: BotPainter(
                frame: e.sample(t),
                bodyColor: const Color(0xFFFFFFFF),
                eyeColor: const Color(0xFF134E32),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shouldRepaint es false con el mismo frame', (tester) async {
    final e = BotEngine();
    final f = e.sample(1.0);
    const blanco = Color(0xFFFFFFFF);
    const verde = Color(0xFF134E32);
    final a = BotPainter(frame: f, bodyColor: blanco, eyeColor: verde);
    final b = BotPainter(frame: f, bodyColor: blanco, eyeColor: verde);
    expect(a.shouldRepaint(b), isFalse);
  });

  testWidgets('shouldRepaint es true con frames distintos', (tester) async {
    final e = BotEngine();
    const blanco = Color(0xFFFFFFFF);
    const verde = Color(0xFF134E32);
    final a = BotPainter(frame: e.sample(0.0), bodyColor: blanco, eyeColor: verde);
    final b = BotPainter(frame: e.sample(1.0), bodyColor: blanco, eyeColor: verde);
    expect(a.shouldRepaint(b), isTrue);
  });

  for (final caso in <String, BotMood>{
    'idle': BotMood.idle,
    'thinking': BotMood.thinking,
    'sleeping': BotMood.sleeping,
  }.entries) {
    testWidgets('golden ${caso.key}', (tester) async {
      final e = BotEngine()..hold(caso.value);
      await tester.pumpWidget(_caja(e, 2.0));
      await expectLater(
        find.byKey(kBlobKey),
        matchesGoldenFile('goldens/bot_${caso.key}.png'),
      );
    });
  }

  testWidgets('golden pleased', (tester) async {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.pleased);
    await tester.pumpWidget(_caja(e, 0.45)); // mitad del pulse: guino cerrado
    await expectLater(
      find.byKey(kBlobKey),
      matchesGoldenFile('goldens/bot_pleased.png'),
    );
  });

  testWidgets('golden surprised', (tester) async {
    final e = BotEngine();
    e.sample(0);
    e.pulse(BotMood.surprised);
    await tester.pumpWidget(_caja(e, 0.45));
    await expectLater(
      find.byKey(kBlobKey),
      matchesGoldenFile('goldens/bot_surprised.png'),
    );
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/bot/bot_painter_test.dart`
Expected: FAIL — `bot_painter.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/bot/presentation/bot_painter.dart
import 'dart:typed_data';

import 'package:flutter/rendering.dart';

import '../domain/bot_frame.dart';
import 'bot_path.dart';

class BotPainter extends CustomPainter {
  final BotFrame frame;
  final Color bodyColor;
  final Color eyeColor;

  const BotPainter({
    required this.frame,
    required this.bodyColor,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r0 = size.shortestSide / 2;
    final ox = size.width / 2;
    final oy = size.height / 2;

    if (frame.bodyAlpha > 0.001) {
      final cuerpo = closedCatmullRomPath(profilePoints(frame, size));
      canvas.drawPath(
        cuerpo,
        Paint()
          ..color = bodyColor.withValues(alpha: frame.bodyAlpha)
          ..isAntiAlias = true,
      );
    }

    for (final e in frame.eyes) {
      if (e.alpha <= 0.001 || e.ry <= 0.001) continue;
      // El ojo NO se dibuja alineado al eje: `EyeSpec` trae una matriz 2x2
      // (a,b,c,d) con el repere tangente a la esfera, y es lo que da el
      // escorzo. Dibujar un RRect recto tiraría esa informacion.
      // Matrix4.storage es column-major: [col*4 + row].
      final m = Float64List(16)
        ..[0] = e.a   // m00
        ..[1] = e.b   // m10
        ..[4] = e.c   // m01
        ..[5] = e.d   // m11
        ..[10] = 1
        ..[15] = 1;
      canvas.save();
      canvas.translate(ox + e.cx * r0, oy + e.cy * r0);
      canvas.transform(m);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: e.rx * 2 * r0,
        height: e.ry * 2 * r0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(e.rx * r0)),
        Paint()..color = eyeColor.withValues(alpha: e.alpha),
      );
      canvas.restore();
    }

    for (final d in frame.dots) {
      if (d.alpha <= 0.001) continue;
      canvas.drawCircle(
        Offset(ox + d.cx * r0, oy + d.cy * r0),
        d.r * r0,
        Paint()..color = bodyColor.withValues(alpha: d.alpha),
      );
    }
  }

  // `covariant` es obligatorio: CustomPainter declara shouldRepaint(CustomPainter),
  // y estrechar el tipo del parametro sin covariant es error de compilacion.
  @override
  bool shouldRepaint(covariant BotPainter old) =>
      old.frame != frame || old.bodyColor != bodyColor || old.eyeColor != eyeColor;
}
```

- [ ] **Step 4: Generar los goldens**

Run: `flutter test --update-goldens test/features/bot/bot_painter_test.dart`
Expected: PASS, y aparecen 5 PNG en `test/features/bot/goldens/`.

- [ ] **Step 5: Mirar los PNG con tus ojos**

Abre los cinco. Esto no lo verifica ningún assert: comprueba que el blob se ve como un blob, que los ojos están dentro del cuerpo y no flotando fuera, y que `thinking` muestra tres puntos alineados. Si algo se ve mal, el problema está en las poses de Task 4, no aquí.

- [ ] **Step 6: Ejecutar los tests contra los goldens ya generados**

Run: `flutter test test/features/bot/bot_painter_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 7: Commit**

```bash
git add lib/features/bot/presentation/bot_painter.dart test/features/bot/bot_painter_test.dart test/features/bot/goldens/
git commit -m "feat(bot): painter del blob con goldens de los cinco estados"
```

---

### Task 6: El widget con ticker

**Files:**
- Create: `lib/features/bot/presentation/bot_avatar.dart`
- Test: `test/features/bot/bot_avatar_test.dart`

**Interfaces:**
- Consumes: `BotEngine`, `BotMood` (Task 3), `BotPainter` (Task 5).
- Produces: `class BotAvatar extends StatefulWidget` con constructor `BotAvatar({Key? key, required BotMood mood, Object? pulseToken, BotMood? pulseMood, double size = 50, Color bodyColor = const Color(0xFFFFFFFF), Color eyeColor = const Color(0xFF134E32)})`.

El widget recibe el mood sostenido por parámetro y **repropaga** los cambios al motor en `didUpdateWidget`. El `pulse` es un valor que, cuando cambia a no-nulo, dispara `engine.pulse()` una vez.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/bot/bot_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/bot/presentation/bot_avatar.dart';
import 'package:nutriapp/features/bot/presentation/bot_painter.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

BotPainter _painterActual(WidgetTester tester) {
  final cp = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(BotAvatar), matching: find.byType(CustomPaint)).last,
  );
  return cp.painter! as BotPainter;
}

void main() {
  testWidgets('se monta y pinta con un BotPainter', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle)));
    expect(find.byType(BotAvatar), findsOneWidget);
    expect(_painterActual(tester), isA<BotPainter>());
  });

  testWidgets('el frame avanza con el tiempo', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    final antes = _painterActual(tester).frame;
    await tester.pump(const Duration(milliseconds: 300));
    expect(_painterActual(tester).frame, isNot(equals(antes)));
  });

  testWidgets('cambiar el mood por parametro llega al motor', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painterActual(tester).frame.dots, isEmpty);

    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painterActual(tester).frame.dots.length, equals(3));
  });

  testWidgets('respeta el tamano pedido', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.idle, size: 32)));
    final box = tester.getSize(find.byType(BotAvatar));
    expect(box.width, equals(32));
    expect(box.height, equals(32));
  });

  testWidgets('se desmonta sin dejar el ticker vivo', (tester) async {
    await tester.pumpWidget(_app(const BotAvatar(mood: BotMood.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    // Si el ticker sobreviviera al dispose, flutter_test falla el test
    // automaticamente al terminar con "A Ticker was active when disposed".
    expect(find.byType(BotAvatar), findsNothing);
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/bot/bot_avatar_test.dart`
Expected: FAIL — `bot_avatar.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
// lib/features/bot/presentation/bot_avatar.dart
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

  final double size;
  final Color bodyColor;
  final Color eyeColor;

  const BotAvatar({
    super.key,
    required this.mood,
    this.pulseToken,
    this.pulseMood,
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
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Cadencia por mood: descartamos los frames que llegan demasiado pronto.
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
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/bot/bot_avatar_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/bot/presentation/bot_avatar.dart test/features/bot/bot_avatar_test.dart
git commit -m "feat(bot): widget BotAvatar con ticker y cadencia por mood"
```

---

### Task 7: Estado compartido

**Files:**
- Create: `lib/core/state/bot_mood_state.dart`
- Test: `test/core/state/bot_mood_state_test.dart`

**Interfaces:**
- Consumes: `BotMood` (Task 1).
- Produces: `class BotMoodState extends ChangeNotifier` con `BotMood get mood`, `Object? get pulseToken`, `BotMood? get pulseMood`, `void hold(BotMood)`, `void pulse(BotMood)`; y `BotMoodState.instance`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/state/bot_mood_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

void main() {
  test('arranca en idle', () {
    expect(BotMoodState().mood, equals(BotMood.idle));
  });

  test('hold notifica solo cuando el valor cambia', () {
    final s = BotMoodState();
    var avisos = 0;
    s.addListener(() => avisos++);

    s.hold(BotMood.thinking);
    expect(avisos, equals(1));

    s.hold(BotMood.thinking); // mismo valor: no debe notificar
    expect(avisos, equals(1));

    s.hold(BotMood.idle);
    expect(avisos, equals(2));
  });

  test('hold ignora los moods transitorios', () {
    final s = BotMoodState();
    s.hold(BotMood.pleased);
    expect(s.mood, equals(BotMood.idle));
  });

  test('pulse cambia el token en cada llamada', () {
    final s = BotMoodState();
    s.pulse(BotMood.pleased);
    final t1 = s.pulseToken;
    s.pulse(BotMood.pleased);
    expect(s.pulseToken, isNot(equals(t1)));
    expect(s.pulseMood, equals(BotMood.pleased));
  });

  test('pulse ignora los moods sostenidos', () {
    final s = BotMoodState();
    s.pulse(BotMood.thinking);
    expect(s.pulseToken, isNull);
  });

  test('instance devuelve siempre el mismo objeto', () {
    expect(identical(BotMoodState.instance, BotMoodState.instance), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/core/state/bot_mood_state_test.dart`
Expected: FAIL — `bot_mood_state.dart` no existe.

- [ ] **Step 3: Implementar**

```dart
// lib/core/state/bot_mood_state.dart
import 'package:flutter/foundation.dart';

import '../../features/bot/domain/bot_mood.dart';

/// Puente entre el chat y la nav bar. Sigue el patron de DioClient.rateLimit:
/// un ChangeNotifier compartido, sin meter provider en el proyecto.
class BotMoodState extends ChangeNotifier {
  static final BotMoodState instance = BotMoodState();

  BotMood _mood = BotMood.idle;
  BotMood get mood => _mood;

  int _token = 0;
  Object? _pulseToken;
  BotMood? _pulseMood;
  Object? get pulseToken => _pulseToken;
  BotMood? get pulseMood => _pulseMood;

  /// Fija un mood sostenido (idle, thinking, sleeping).
  void hold(BotMood m) {
    if (m.isTransient) return;
    if (m == _mood) return;
    _mood = m;
    notifyListeners();
  }

  /// Dispara un mood transitorio (pleased, surprised). El token cambia en cada
  /// llamada para que el widget distinga dos pulses seguidos del mismo tipo.
  void pulse(BotMood m) {
    if (!m.isTransient) return;
    _pulseMood = m;
    _pulseToken = ++_token;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/core/state/bot_mood_state_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/state/bot_mood_state.dart test/core/state/bot_mood_state_test.dart
git commit -m "feat(bot): BotMoodState compartido entre chat y nav bar"
```

---

### Task 8: Cablear la nav bar

**Files:**
- Modify: `lib/core/widgets/custom_bottom_nav_bar.dart:78-120` (`_buildCenterItem`)
- Test: `test/core/widgets/custom_bottom_nav_bar_test.dart`

**Interfaces:**
- Consumes: `BotAvatar` (Task 6), `BotMoodState` (Task 7).
- Produces: nada nuevo; `CustomBottomNavBar` mantiene su firma actual (`selectedIndex`, `onTabSelected`).

El círculo con gradiente y el `Transform.translate` **no se tocan**. Solo se sustituye el `Icon` interior por el `BotAvatar`, envuelto en un `ListenableBuilder`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/widgets/custom_bottom_nav_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/core/widgets/custom_bottom_nav_bar.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/bot/presentation/bot_avatar.dart';

Widget _app({required void Function(int) onTab}) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: CustomBottomNavBar(selectedIndex: 2, onTabSelected: onTab),
      ),
    );

void main() {
  setUp(() {
    BotMoodState.instance.hold(BotMood.idle);
  });

  testWidgets('el boton IA pinta un BotAvatar en vez del icono', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    expect(find.byType(BotAvatar), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
  });

  testWidgets('los otros cuatro tabs conservan sus iconos', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('tocar el boton IA sigue notificando el indice 2', (tester) async {
    int? tocado;
    await tester.pumpWidget(_app(onTab: (i) => tocado = i));
    await tester.tap(find.byType(BotAvatar));
    await tester.pump();
    expect(tocado, equals(2));
  });

  testWidgets('tocar el boton IA dispara un pulse de sorpresa', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    // BotMoodState.instance es un singleton que sobrevive entre tests del
    // fichero, asi que comparamos el token antes/despues en vez de asumir null.
    final antes = BotMoodState.instance.pulseToken;
    await tester.tap(find.byType(BotAvatar));
    await tester.pump();
    expect(BotMoodState.instance.pulseToken, isNot(equals(antes)));
    expect(BotMoodState.instance.pulseMood, equals(BotMood.surprised));
  });

  testWidgets('el avatar refleja el mood del estado compartido', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    BotMoodState.instance.hold(BotMood.thinking);
    await tester.pump();
    expect(tester.widget<BotAvatar>(find.byType(BotAvatar)).mood, equals(BotMood.thinking));
  });
}
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/core/widgets/custom_bottom_nav_bar_test.dart`
Expected: FAIL — no hay ningún `BotAvatar`; se encuentra `Icons.auto_awesome_rounded`.

- [ ] **Step 3: Sustituir el icono por el avatar**

En `custom_bottom_nav_bar.dart`, añade los imports:

```dart
import '../state/bot_mood_state.dart';
import '../../features/bot/domain/bot_mood.dart';
import '../../features/bot/presentation/bot_avatar.dart';
```

Cambia la llamada en el `Row` para que no pase icono:

```dart
_buildCenterItem(2, 'IA'),
```

Y reemplaza `_buildCenterItem` entero por:

```dart
  Widget _buildCenterItem(int index, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        BotMoodState.instance.pulse(BotMood.surprised);
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0A6B3F), Color(0xFF1E56F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // El blob va metido dentro del circulo, no a ras: a 50px llenaria
              // el boton entero de blanco y taparia el gradiente de marca.
              child: Center(
                child: ListenableBuilder(
                  listenable: BotMoodState.instance,
                  builder: (context, _) {
                    final s = BotMoodState.instance;
                    return BotAvatar(
                      mood: s.mood,
                      pulseToken: s.pulseToken,
                      pulseMood: s.pulseMood,
                      // 39, no 34: el blob deja un margen de 1/1.15 dentro de
                      // su lienzo (ver kRestBallFraction), asi que la bola
                      // visible mide 39 * 0.8696 = 33.9px. Ese margen es lo que
                      // evita que `surprised` (escala 1.06) se recorte.
                      size: 39,
                    );
                  },
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E56F5) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/core/widgets/custom_bottom_nav_bar_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Ejecutar TODA la suite para descartar regresiones**

Run: `flutter test`
Expected: PASS. Si algún test de otra feature rompe por el import nuevo, arréglalo antes de commitear.

- [ ] **Step 6: Commit**

```bash
git add lib/core/widgets/custom_bottom_nav_bar.dart test/core/widgets/custom_bottom_nav_bar_test.dart
git commit -m "feat(bot): el boton IA pinta el blob animado en vez del icono"
```

---

### Task 9: Cablear el chat y el rate limit

**Files:**
- Modify: `lib/features/chatbot/presentation/controllers/chat_view_model.dart:55` y `:92`
- Modify: `lib/features/chatbot/presentation/screens/ai_chat_view.dart` (`initState` / `dispose`)
- Test: `test/features/chatbot/chat_view_model_bot_mood_test.dart`

**Interfaces:**
- Consumes: `BotMoodState` (Task 7), `DioClient.rateLimit` (ya existe).
- Produces: nada nuevo.

- [ ] **Step 1: Leer el view model antes de tocarlo**

Run: `sed -n '40,100p' lib/features/chatbot/presentation/controllers/chat_view_model.dart`

Localiza las líneas exactas donde `_isLoading` pasa a `true` (≈55) y vuelve a `false` (≈92). Los números de línea del plan son de referencia; usa los reales.

- [ ] **Step 2: Escribir el test que falla**

`ChatRepository` es una clase concreta, no una interfaz, así que el doble la **extiende** y sobrescribe `sendMessage`. `ChatViewModel` ya acepta la inyección: `ChatViewModel({ChatRepository? repository})`.

```dart
// test/features/chatbot/chat_view_model_bot_mood_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/chatbot/data/chat_repository.dart';
import 'package:nutriapp/features/chatbot/presentation/controllers/chat_view_model.dart';

/// Doble que nos deja controlar cuando "responde" la IA.
class _RepoFalso extends ChatRepository {
  final Completer<ChatResponse> completer = Completer<ChatResponse>();

  @override
  Future<ChatResponse> sendMessage(String message,
      {List<int> fridgeItemIds = const []}) {
    return completer.future;
  }

  void responde(String texto) => completer.complete(
        ChatResponse(type: ChatResponseType.chat, text: texto),
      );

  void falla() => completer.completeError(Exception('boom'));
}

void main() {
  setUp(() => BotMoodState.instance.hold(BotMood.idle));

  test('mientras espera la respuesta, el bot piensa', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    final envio = vm.sendMessage('hola');
    expect(BotMoodState.instance.mood, equals(BotMood.thinking));

    repo.responde('que tal');
    await envio;
    vm.dispose();
  });

  test('al llegar la respuesta deja de pensar y guina', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    final envio = vm.sendMessage('hola');
    repo.responde('que tal');
    await envio;

    expect(BotMoodState.instance.mood, equals(BotMood.idle));
    expect(BotMoodState.instance.pulseMood, equals(BotMood.pleased));
    vm.dispose();
  });

  test('si el envio falla, deja de pensar pero NO guina', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    // Singleton compartido entre tests: el token de partida puede no ser null.
    final antes = BotMoodState.instance.pulseToken;
    final envio = vm.sendMessage('hola');
    repo.falla();
    await envio;

    expect(BotMoodState.instance.mood, equals(BotMood.idle));
    expect(BotMoodState.instance.pulseToken, equals(antes));
    vm.dispose();
  });
}
```

Nota: `vm.dispose()` al final de cada test cancela el `Timer.periodic` del efecto máquina de escribir (`_startTypewriter`); sin eso `flutter_test` se queja de timers pendientes.

- [ ] **Step 3: Ejecutar el test y verificar que falla**

Run: `flutter test test/features/chatbot/chat_view_model_bot_mood_test.dart`
Expected: FAIL — el mood se queda en `idle`.

- [ ] **Step 4: Empujar el mood desde el view model**

Añade los imports en `chat_view_model.dart`:

```dart
import '../../../../core/network/dio_client.dart';
import '../../../../core/state/bot_mood_state.dart';
import '../../../bot/domain/bot_mood.dart';
```

En `sendMessage`, justo después de `_isLoading = true;` (queda antes de `notifyListeners()`):

```dart
    _isLoading = true;
    _errorMessage = null;
    BotMoodState.instance.hold(BotMood.thinking);
    notifyListeners();
```

Y el bloque `finally` que ya existe al final de `sendMessage` pasa a:

```dart
    } finally {
      _isLoading = false;
      BotMoodState.instance.hold(BotMood.idle);
      // hold(idle) va antes del pulse: pulse solo se aplica sobre idle.
      // Sin el guard del rate limit, agotar el limite haria guinar al bot,
      // porque esa rama hace return sin poner _errorMessage.
      if (_errorMessage == null && !DioClient.rateLimit.isExhausted) {
        BotMoodState.instance.pulse(BotMood.pleased);
      }
      notifyListeners();
    }
```

Dos detalles del código real que importan aquí:

- `_isLoading = false` vive en un `finally`, así que corre también cuando `sendMessage` sale por el `return` temprano de `RateLimitException`. Por eso hace falta el guard.
- El texto de la respuesta se anima con `_startTypewriter`, que arranca un `Timer.periodic`. El guiño se dispara cuando llega la respuesta, no cuando termina de escribirse. Es lo que queremos.

- [ ] **Step 5: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/features/chatbot/chat_view_model_bot_mood_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 6: Conectar el rate limit**

En `ai_chat_view.dart`, dentro de `initState`, después de crear el view model:

```dart
DioClient.rateLimit.addListener(_syncBotSleep);
```

Añade el método y el `dispose`:

```dart
  void _syncBotSleep() {
    BotMoodState.instance.hold(
      DioClient.rateLimit.isExhausted ? BotMood.sleeping : BotMood.idle,
    );
  }
```

```dart
  @override
  void dispose() {
    DioClient.rateLimit.removeListener(_syncBotSleep);
    super.dispose();
  }
```

Si `dispose` ya existe, añade solo la línea del `removeListener` al principio. Importa `DioClient`, `BotMoodState` y `BotMood`.

- [ ] **Step 7: Ejecutar TODA la suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 8: Verificar en la app de verdad**

Run: `flutter run`

Comprueba con tus ojos, en este orden:
1. El botón IA respira despacio y parpadea de vez en cuando.
2. Al tocarlo, da un respingo (ojos grandes).
3. Manda un mensaje: el blob desaparece y salen tres puntos pulsantes.
4. Al llegar la respuesta, vuelve el blob y guiña una vez.
5. Cambia a otra pestaña y vuelve: sigue animando, sin parpadeos raros ni saltos.

Nada de esto lo cubren los tests. Si el paso 3 o 4 no dispara, el problema está en el cableado del Step 4, no en el motor.

- [ ] **Step 9: Commit**

```bash
git add lib/features/chatbot/ test/features/chatbot/chat_view_model_bot_mood_test.dart
git commit -m "feat(bot): el chat y el rate limit empujan el mood del blob"
```

---

## Notas para quien ejecute esto

- **El motor es Dart plano a propósito.** Si en algún momento te apetece importar `dart:ui` en `lib/features/bot/domain/`, para y busca otra forma: esa restricción es lo que hace que 25 de los ~40 tests corran sin levantar el binding de Flutter.
- **Los goldens fallan en CI si se generaron en otra plataforma.** El antialiasing de fuentes y formas difiere entre Windows, macOS y Linux. Si montas CI, genera los goldens en la misma plataforma que corre CI, o marca esos tests con `@Tags(['golden'])` y exclúyelos.
- **No hay prerrequisitos externos.** El fuente de Bloub ya se leyó y sus constantes están tabuladas dentro de la Task 3; no hace falta clonar nada para implementar.
- **La parte delicada es el orden de las tres rotaciones en `_computeRestEyes`.** Si los ojos salen fuera de la bola o superpuestos, es ahí. El test `bot_eyes_test.dart` lo caza.
