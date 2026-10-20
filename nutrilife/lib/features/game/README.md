# Juego de la nutria (tipo tamagotchi)

Mini juego didáctico dentro de NutriLife: una nutria en pixel art que reacciona a lo que haces con ella.
**Estado actual:** solo existe el gesto de **acariciar**. La nutria se acaricia pasando el dedo por encima; no hay un botón visible para eso.

## Cómo se entra

En **Inicio** (`DashboardScreen`) hay una tarjeta "Juega con tu nutria", debajo de la tarjeta de la IA. Al tocarla se abre `OtterPetScreen` con `Navigator.push`, igual que las demás pantallas secundarias de la app.

La tarjeta es `HomeShortcutCard` (`lib/features/home/presentation/widgets/home_shortcut_card.dart`). Es la antigua `AiSuggestionCard`, convertida en genérica para que la usen las dos tarjetas: recibe `leading`, `title`, `subtitle` y `onTap`.

## Tecnologías

Solo Flutter y su SDK, **sin dependencias nuevas** (no se usa Flame ni otro motor de juegos):

| Necesidad | Qué se usó |
| --- | --- |
| Dibujar un cuadro del spritesheet | `Image.asset` con `BoxFit.cover` + `Alignment` |
| Pixel art nítido al escalar | `FilterQuality.none` |
| Reloj de la animación | `Ticker` (`SingleTickerProviderStateMixin`) |
| Detectar el dedo | `Listener.onPointerMove` |
| Vibración | `HapticFeedback` (`flutter/services`) |
| Corazones que suben | `Stack` + `Positioned` + `Opacity`, calculados en cada tick |
| Textos | ARB (`lib/l10n/app_es.arb` y `app_en.arb`), igual que el resto de la app |

## Archivos

```text
lib/features/game/
├── README.md                              ← este documento
└── presentation/
    ├── screens/otter_pet_screen.dart      ← pantalla, gesto y animación
    └── widgets/otter_sprite.dart          ← dibuja un cuadro de un spritesheet

assets/game/otter/                         ← registrado en pubspec.yaml
├── idle.png                               ← reposo (3072×512, 6 cuadros)
└── happiness.png                          ← salto de alegría (3072×512, 6 cuadros)

test/features/game/otter_pet_screen_test.dart
```

## Assets

El origen está en `nutrilifeGame/` en la raíz del repo, con todas las nutrias, ropas, fondos y comida. Lee su `README.md` antes de agregar animaciones.

La nutria base es `nutrilifeGame/NutriLife_normal_sin_ropa/NutriLife_normal_sin_ropa/`:

- Cada acción tiene una carpeta con `frames/` (6 PNG de 512×512), un **spritesheet** `<acción>.png` de 3072×512 (los 6 cuadros en una fila, de izquierda a derecha y sin margen), un GIF de vista previa y un `animation.json` con fps, loop y eventos por cuadro.
- Acciones disponibles: `idle`, `eat`, `sleep`, `wake`, `curiosity`, `idea`, `sadness`, `happiness`, `jump`, `look_around`, `healthy_recovery`, `interaction_special`.
- `previews/sequence_review_*.jpg` muestran todas las secuencias de un vistazo.

**En la app solo se copian los spritesheets que se usan**: cada uno pesa unos 780 KB y va dentro del APK/IPA. Los cuadros sueltos sumados pesan más (unos 1,2 MB por acción), así que no se usan.

Para agregar una animación:

1. Copia `nutrilifeGame/.../<acción>/<acción>.png` a `nutrilife/assets/game/otter/`. La carpeta ya está en `pubspec.yaml`, no hay que tocarlo.
2. Agrega su ruta como constante en `OtterSprite`, junto a `idleSheet` y `happinessSheet`.

## Cómo se dibuja un cuadro (`OtterSprite`)

La hoja es 6 veces más ancha que alta. Dentro de una caja cuadrada, `BoxFit.cover` la escala a la altura de la caja, y la `Alignment` horizontal elige qué parte del ancho se ve:

```text
alignment.x = -1 + 2 * frame / 5      // frame 0 → -1 (izquierda), frame 5 → 1 (derecha)
```

Flutter (`paintImage`) recorta exactamente esa franja de la imagen original, así que no hace falta `ClipRect` ni `CustomPainter`. `gaplessPlayback: true` evita un parpadeo al cambiar de hoja.

## Bucle de animación

Un solo `Ticker` hace `setState` en cada frame de pantalla (60 fps) y guarda el tiempo transcurrido en `_now`. **El sprite no cambia a 60 fps**: el cuadro se calcula a partir de `_now` y los fps de cada estado. Esos 60 fps solo mueven con suavidad los corazones y la escala.

Estados (getter `_sprite`), en orden de prioridad:

| Estado | Cuándo | Qué se ve |
| --- | --- | --- |
| Feliz | Durante `_happyDuration` después de `_celebrate()` | `happiness`, cuadros 0→5 a `_happyFps` (6 fps), una sola vez |
| Acariciada | Hubo roce en los últimos `_strokeGrace` (150 ms) | `idle`, cuadro 2 fijo (ojos cerrados y sonrisa) y escala 0,96 |
| Reposo | El resto del tiempo | `idle`, cuadro 0 quieto durante `_idleRestMs` (3,5 s); luego la secuencia completa una vez a `_idleFps` (6 fps) |

**Por qué estos fps y no los del `animation.json`** (8 y 10 fps): los 6 cuadros de cada acción son todos un poco distintos. En bucle continuo la nutria parecía hiperactiva o temblorosa. Por eso en reposo se queda quieta y solo de vez en cuando parpadea y mueve las orejas.

## El gesto de acariciar

Está en `_onPointerMove`:

1. El `Listener` envuelve la caja de la nutria (280×280). Solo recibe el movimiento de un dedo que **empezó** sobre ella.
2. Se ignora el 15 % de cada borde (`deflate`) porque el sprite tiene margen transparente. Así solo cuenta el roce sobre el cuerpo.
3. Cada evento suma `e.delta.distance` (píxeles lógicos recorridos) a dos contadores:
   - `_sinceHeart`: cada `_heartEvery` (60 px) sale un corazón en la posición del dedo, con una vibración suave (`selectionClick`).
   - `_petDistance`: al llegar a `_petsToHappy` (900 px, unas 4 o 5 pasadas) se llama a `_celebrate()`. Eso dispara la animación de alegría, 8 corazones, una vibración fuerte (`mediumImpact`) y el texto "¡Le encantó! 💚" durante 2 s. Después el contador vuelve a 0.
4. Un toque sin mover el dedo no genera `delta`, así que no cuenta.
5. Mientras dura la alegría se ignoran las caricias.

Los corazones (`_Heart`) guardan su origen, una deriva horizontal aleatoria y su momento de nacimiento. En cada tick se dibujan según su edad `t ∈ [0,1]`: suben 90 px y se desvanecen. Se borran al pasar `_heartLife` (1 s). Van dentro de `IgnorePointer` para no robar el gesto.

**Accesibilidad:** con TalkBack/VoiceOver no se puede hacer el gesto. Por eso `Semantics` le da a la nutria la etiqueta del hint y un `onTap`: un doble toque del lector equivale a una caricia completa.

## Ajustes rápidos

Todo está en constantes al inicio de `_OtterPetScreenState`:

| Constante | Efecto |
| --- | --- |
| `_petsToHappy` | Cuánto hay que acariciar para que salte de alegría |
| `_heartEvery` | Cada cuánto recorrido sale un corazón |
| `_idleRestMs` | Cada cuánto parpadea o se mueve en reposo |
| `_idleFps`, `_happyFps` | Velocidad de las secuencias |
| `_otterSize` | Tamaño de la nutria en pantalla |

Para ver un cambio: hot reload (`r`) en `flutter run`. Si un `static const` no se actualiza, usa hot restart (`R`).

## Tests

`test/features/game/otter_pet_screen_test.dart` comprueba que:

- acariciar con el dedo saca corazones y, tras varias pasadas, muestra "¡Le encantó! 💚";
- los toques sin mover el dedo no cuentan.

```bash
flutter test test/features/game
```

## Lo que falta / ideas para continuar

- **Persistencia:** hoy nada se guarda; al salir de la pantalla la nutria olvida todo. Para un tamagotchi real faltan estados (cariño, hambre, energía) guardados con `shared_preferences` (ya está en la app) o en el backend, y que bajen con el tiempo.
- **Más interacciones** con las otras acciones: dar de comer (`eat`, con la comida como objeto aparte, ver el README de assets y la carpeta `nutrilifeGame/comida`), dormir/despertar (`sleep` se reproduce una vez y se queda en el último cuadro; luego `wake`), tristeza si la descuidas (`sadness`), etc.
- **Ropa, fondos y nutrias desbloqueables:** están en `nutrilifeGame/` (`nutrias_vestimenta`, `fondos`, `nutrias_desbloqueables`…) y todavía no se usan.
- **Separar la lógica** si el juego crece: hoy todo el estado vive en el `State` de la pantalla. Con más estados conviene moverlo a una clase propia (por ejemplo un `ChangeNotifier`, como `core/state/` en el resto de la app) para probarlo sin widgets.
