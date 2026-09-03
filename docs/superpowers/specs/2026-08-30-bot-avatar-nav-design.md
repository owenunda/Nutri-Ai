# Diseño: avatar animado (blob Bloub) en el botón IA de la nav bar

Fecha: 2026-08-30
Estado: aprobado

## Objetivo

Sustituir el icono estático `Icons.auto_awesome_rounded` del botón central "IA" de la barra de
navegación por un avatar animado —el blob de [Bloub](https://github.com/jeremy-prt/bloub)—
que reacciona al estado real del chat: respira en reposo, piensa mientras la IA responde,
guiña al recibir respuesta y se duerme cuando se agota el límite de peticiones.

La nutria (`nutria_logo.png`) del header del chat **no se toca**. Blob y nutria conviven:
el blob es el indicador de estado en la nav bar, la nutria sigue siendo la mascota del chat.

## Contexto del código actual

Verificado contra el código, no contra la documentación.

- `lib/core/widgets/custom_bottom_nav_bar.dart` — `_buildCenterItem` (línea 78) dibuja el
  botón IA: círculo de 50×50, gradiente `#0A6B3F → #1E56F5`, icono blanco de 24px.
  El widget es `StatelessWidget` y recibe `selectedIndex` + `onTabSelected`.
- `lib/features/chatbot/presentation/screens/ai_chat_view.dart:28` — `ChatViewModel` se
  instancia **dentro** de la pantalla del chat. La nav bar, que vive en `DashboardScreen`,
  no tiene acceso a él.
- `lib/features/chatbot/presentation/controllers/chat_view_model.dart` — `ChangeNotifier`
  con `isLoading` (líneas 14, 19, 55, 92).
- `lib/core/network/dio_client.dart:15` — `static final RateLimitState rateLimit = RateLimitState();`
  Precedente ya establecido en el proyecto de `ChangeNotifier` singleton compartido.
- `pubspec.yaml` — sin `provider` ni `riverpod`. El proyecto usa `ChangeNotifier` +
  `ListenableBuilder` a mano. El diseño respeta esa elección y **no añade dependencias**.

## Qué se porta de Bloub, y qué no

Bloub es Vue 3 + TypeScript; NutriApp es Flutter. No hay integración posible, solo porte.

La decisión tomada es **portar los datos, no el motor**: la fidelidad visual de Bloub está en
sus números (su README indica que cada valor sale de medir el vídeo original frame a frame),
no en su arquitectura TypeScript. Extraemos las tablas y escribimos un motor pequeño.

### Representación de las formas (verificado en `shape.ts`)

Las siluetas **no** son puntos de control Bézier. Son perfiles radiales:

```
radii: number[]   // PROFILE_SAMPLES (64) radios en ángulos equiespaciados
rot: number       // rotación en radianes
cx, cy: number    // desplazamiento del centro
sx, sy: number    // squash/stretch en espacio de pantalla
```

Todas las formas comparten el mismo número de muestras, así que el morphing es interpolación
lineal de 64 números más lerp de la transform (la rotación por el camino más corto). El path
Bézier se genera después con splines Catmull-Rom sobre los puntos muestreados.

Esto encaja directamente con `Path.cubicTo` de Flutter y **elimina la necesidad de parsear
strings SVG en runtime** — no se usa `path_drawing` ni ninguna librería de morphing.

### Estados portados

Cinco de los catorce. Bloub **no tiene** un estado "happy"; para la respuesta recibida se usa
`wink`.

| Señal en NutriApp | `BotMood` | Estado Bloub | Comportamiento |
|---|---|---|---|
| Reposo | `idle` | `idle` | Respira y parpadea |
| `ChatViewModel.isLoading == true` | `thinking` | `thinking` | Tres puntos pulsantes; el blob desaparece |
| Respuesta recibida | `pleased` | `wink` | Guiño breve, vuelve a `idle` |
| Tap en el botón IA | `surprised` | `wide` | Ojos grandes, reacción corta, vuelve a `idle` |
| `DioClient.rateLimit.isExhausted` | `sleeping` | `sleep` | Esferita rebotando |

`pleased` y `surprised` son **transitorios**: se disparan con `pulse()`, duran lo que dure su
animación y vuelven solos a `idle`. `thinking` y `sleeping` son **sostenidos**: duran mientras
la señal que los provoca siga activa.

No se portan: `decor.ts` (dots/arcs), `eyefit.ts` (encaje de ojos sub-pixel, invisible a 50px),
`cycles.ts`, `skins.ts`, ni las formas alternativas (hexágono, huevo, triángulo, cometa…).

### Encuadre visual

El blob va **en blanco, en negativo**, dentro del círculo con el gradiente de marca existente.
Los ojos van en verde oscuro (`#134E32`). Razón: a 50px reales el blob ocupa ~34px, y el negro
original de Bloub sobre el gradiente verde oscuro no contrasta lo suficiente. El botón sigue
siendo reconociblemente NutriAI.

## Arquitectura

Rutas relativas a `nutriapp/`:

```
lib/features/bot/
  data/bot_profiles.dart          constantes: radii[64] por forma (dato portado de Bloub)
  domain/bot_frame.dart           BotFrame, EyeSpec — value objects inmutables
  domain/bot_engine.dart          sample(t) -> BotFrame — Dart puro, SIN dart:ui
  domain/bot_mood.dart            enum BotMood { idle, thinking, pleased, surprised, sleeping }
  presentation/bot_painter.dart   CustomPainter: BotFrame -> Canvas
  presentation/bot_avatar.dart    StatefulWidget con Ticker
lib/core/state/bot_mood_state.dart   ChangeNotifier singleton
tool/extract_bloub_profiles.dart     script de un solo uso
test/features/bot/                   tests del motor y goldens del painter
```

### El corte que importa

`bot_engine.dart` **no importa `dart:ui`**. `sample(t)` devuelve números: radios interpolados,
transform y specs de ojos. El painter es el único que convierte Catmull-Rom → `Path` y pinta.

Consecuencia: el motor se testea como Dart plano (rápido, sin binding de Flutter) y el painter
se testea con goldens. Son dos unidades con responsabilidades separadas y se pueden cambiar por
dentro sin romper a la otra.

### Contratos de las unidades

- `BotEngine.sample(double t) -> BotFrame` — función pura del tiempo. Mismo `t`, mismo frame.
  No guarda reloj propio; el widget le pasa el tiempo transcurrido.
- `BotEngine.hold(BotMood)` — fija el mood sostenido; ignora los transitorios.
- `BotEngine.pulse(BotMood)` — dispara un transitorio; solo se aplica sobre `idle`.
- `BotEngine.effectiveMood` — el mood resultante tras aplicar la precedencia.
- `BotEngine.isSettled -> bool` — true cuando no hay transición de mood en vuelo y ningún
  pulse pendiente. No controla el ticker (ver §Rendimiento); sirve para que los tests sepan
  cuándo una transición terminó, y para que `pulse()` no se pise a sí mismo.
- `BotEngine.fpsFor(BotMood) -> int` — cadencia declarada por mood, que el widget respeta.
- `BotPainter(BotFrame frame, Color body, Color eyes)` — sin estado, sin lógica temporal.

## Extracción de datos

`nutriapp/tool/extract_bloub_profiles.dart` lee los `.ts` de Bloub y emite `bot_profiles.dart`.
Se ejecuta una vez y **la salida se commitea**. El script se conserva para que quede rastro
reproducible del origen de cada número, no para ejecutarse en cada build.

El código fuente de Bloub **no se vendoriza** en este repo. El script recibe por argumento la
ruta a un clon local del repo (`--bloub-src <ruta>`); si no se le pasa, falla con un mensaje
que explica cómo clonarlo. Así el repo de NutriAI solo contiene los números extraídos, no una
copia del proyecto ajeno.

Transcribir a mano 64 flotantes por forma es una fuente de errores silenciosos que ningún test
detectaría (un blob ligeramente deforme sigue pasando los tests de continuidad).

## Estado y plomería

`ChatViewModel` es privado de `AiChatView`, así que la nav bar no puede leerlo. En vez de
elevar el view model o añadir `provider`, se sigue el patrón que el proyecto ya usa en
`DioClient.rateLimit`:

`BotMoodState` expone dos operaciones y nada más:

- `hold(BotMood m)` — fija un mood sostenido (`thinking`, `sleeping`, `idle`). Notifica solo
  si el valor cambia, para no repintar de más.
- `pulse(BotMood m)` — dispara un mood transitorio (`pleased`, `surprised`). El motor lo
  reproduce y vuelve a `idle` por su cuenta; `BotMoodState` no lleva temporizadores.

Quién decide el mood efectivo cuando coinciden varias señales: `sleeping` gana sobre todo
(si no puedes pedir, da igual lo demás), después `thinking`, y los `pulse` solo se aplican
sobre `idle`. Esa precedencia vive en `BotEngine`, no repartida entre los llamadores.

- `ChatViewModel` lo empuja: `isLoading = true` → `hold(thinking)`; respuesta OK →
  `hold(idle)` seguido de `pulse(pleased)`.
  Son ~3 líneas añadidas; no se reestructura el view model.
- `CustomBottomNavBar` lo escucha con `ListenableBuilder` y pasa el mood a `BotAvatar`.
- El tap ya lo tiene el propio botón: `onTabSelected` dispara `pulse(surprised)` localmente.
- `sleeping` se deriva de `DioClient.rateLimit.isExhausted`, escuchando ese notifier existente.

`AiChatView` y `ChatViewModel` no cambian por dentro. `CustomBottomNavBar` pasa de
`StatelessWidget` a envolver su botón central en un `ListenableBuilder`.

## Rendimiento

La nav bar está siempre montada, así que un `Ticker` a 60fps permanente es inaceptable.

`idle` respira, así que "cero frames en reposo" no es alcanzable sin matar la animación. En
vez de dormir el ticker, se regula su **cadencia por mood**:

| Mood | Cadencia | Motivo |
|---|---|---|
| `idle` | 15 fps | La respiración tiene periodo ~4s; 15fps es indistinguible de 60 |
| `thinking` | 60 fps | Los puntos pulsan rápido y es el estado que más se mira |
| `pleased`, `surprised` | 60 fps | Transitorios y cortos; la fluidez importa |
| `sleeping` | 30 fps | Rebote lento |

- El widget lleva un único `Ticker`; descarta los frames que caen dentro del intervalo de la
  cadencia activa. `BotEngine.fpsFor(mood)` es quien la declara.
- `Ticker` se silencia solo cuando `TickerMode.of(context)` es false (app en background,
  ruta tapada). Gratis, sin código.
- `BotPainter.shouldRepaint` compara el `BotFrame`, no la identidad del painter.

Coste en reposo: 15 interpolaciones de 64 flotantes y 15 construcciones de path por segundo,
sobre un canvas de 50×50. No hay `Timer` de parpadeo separado; el parpadeo es parte de la
pose de `idle`.

## Testing

TDD. El motor puro permite tests rápidos sin binding de Flutter.

**Motor** (`test/features/bot/bot_engine_test.dart`):
- `blend(a, b, 0)` devuelve exactamente `a`; `blend(a, b, 1)` devuelve exactamente `b`.
- La interpolación de rotación toma el camino corto: de 350° a 10° pasa por 0°, no da la vuelta.
- `sample(t)` es determinista: dos llamadas con el mismo `t` dan frames iguales.
- Cada transición de mood termina en el estado esperado y `isSettled` pasa a true.
- Precedencia: un `pulse(pleased)` durante `thinking` no interrumpe el pensar; `hold(sleeping)`
  sí gana sobre `thinking`.
- Todos los perfiles de `bot_profiles.dart` tienen exactamente 64 radios y ninguno es negativo.

**Painter** (`test/features/bot/bot_painter_test.dart`):
- Golden tests a 50×50 para cada uno de los cinco estados.

**Dato portado** (`test/features/bot/bot_profiles_test.dart`): invariantes, no valores
concretos, para que sigan valiendo si se reextrae. Cada perfil tiene exactamente 64 radios,
todos positivos y normalizados a ≤1, y el contorno es continuo (sin saltos bruscos entre
muestras vecinas). Esto cubre lo que `shape.test.ts` afirma sobre los perfiles; un perfil mal
extraído falla aquí en vez de aparecer como un blob deforme en pantalla.

## Licencia y atribución

Bloub es MIT, así que el porte es legal. Requisitos:

- Cabecera con el aviso de copyright MIT de `jeremy-prt/bloub` en `bot_profiles.dart` y en
  `bot_engine.dart`.
- `THIRD_PARTY_NOTICES.md` en la raíz del repo con el texto completo de la licencia.

Nota de marca: el README de Bloub declara que es una recreación del avatar de x.ai y que no
está afiliado. Se conserva el gradiente y el encuadre de NutriAI (blob blanco en negativo, no
el blob negro original), lo que reduce el parecido con el original. Si el proyecto va a
distribución comercial, conviene revisar si la silueta debe divergir más.

## Fuera de alcance

- La nutria del header del chat (`chat_welcome_header.dart`).
- `assets/images/nutria.gif`, que sigue sin usarse.
- El editor de animaciones, la exportación (SVG/PNG/GIF/MP4) y la i18n de Bloub.
- Los otros nueve estados y las formas alternativas.
- Usar el blob en cualquier pantalla que no sea el botón IA.
