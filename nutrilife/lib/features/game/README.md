# Juego de la nutria (tipo tamagotchi)

Mini juego didáctico dentro de NutriLife: una nutria en pixel art que reacciona a lo que haces con ella.
**Estado actual:**
- **Acariciar:** la nutria se acaricia pasando el dedo por encima; no hay un botón visible para eso.
- **Colección de nutrias:** con el botón de ropa (👕) de la barra de arriba eliges qué nutria te acompaña. Hoy hay 7: **Clásica, Chef, Deportiva, Alien menta, Corredor arcade, Galaxia y Explorador RPG**. La elección se guarda.
- **Lugares:** con el botón de paisaje (🏞) eliges dónde vive. Hay 8: **Habitación, Bosque, Costa, Montaña, Estación espacial, Mirador aurora, Observatorio dorado e Isla de cristal**. La elección se guarda.
- **Día y noche:** el lugar sigue la hora del teléfono (de noche desde las 19:00 hasta las 5:59), y el botón de sol/luna lo cambia a mano.
- **Foco colgante:** en la habitación cuelga un foco. Al tocarlo se prende o se apaga, y de noche, apagado, la habitación queda a oscuras.

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
| Lugares, foco y globo de diálogo | `Image.asset` dentro de un `Stack` a pantalla completa (`LayoutBuilder`) |
| Guardar la nutria y el lugar elegidos | `shared_preferences` (ya estaba en la app) |
| Elegir nutria o lugar | `showModalBottomSheet` con `kSheetAnimation` (`core/theme/motion.dart`), como las demás hojas |
| Miniaturas de los lugares | `Image.asset(cacheWidth: 276)`: se decodifican chicas, no a 1440×2560 |
| Textos | ARB (`lib/l10n/app_es.arb` y `app_en.arb`), igual que el resto de la app |

## Archivos

```text
lib/features/game/
├── README.md                              ← este documento
├── domain/otter_skin.dart                 ← catálogo de nutrias (OtterSkin.all)
├── domain/habitat_scene.dart              ← catálogo de lugares (HabitatScene.all) y regla día/noche
├── data/game_preferences.dart             ← guarda/lee la nutria y el lugar elegidos
└── presentation/
    ├── screens/otter_pet_screen.dart      ← pantalla, gesto, animación, foco
    └── widgets/
        ├── otter_sprite.dart              ← dibuja un cuadro de un spritesheet
        └── game_picker_sheet.dart         ← hoja genérica para elegir nutria o lugar

assets/game/otters/<id>/                   ← una carpeta por nutria, cada una en pubspec.yaml
├── idle.webp                              ← reposo (3072×512, 6 cuadros, WebP sin pérdida)
└── happiness.webp                         ← salto de alegría (3072×512, 6 cuadros)
    (hoy: normal/, chef/, deportiva/, alien_mint/, arcade_racer/, galaxia/, rpg_explorer/)

assets/game/habitat/                       ← registrado en pubspec.yaml
├── <lugar>_dia.webp / <lugar>_noche.webp  ← 8 lugares × 2 (1440×2560, WebP calidad 88)
├── foco_encendido.webp / foco_apagado.webp ← foco colgante (270×521, WebP sin pérdida)
└── globo_dialogo.png                      ← globo vacío para "¡Le encantó!" (454×304)

test/features/game/otter_pet_screen_test.dart
test/features/game/otter_skin_test.dart
test/features/game/habitat_scene_test.dart
```

## Assets

El origen está en `nutrilifeGame/` en la raíz del repo, con todas las nutrias, ropas, fondos y comida. Lee su `README.md` antes de agregar animaciones.

La nutria base es `nutrilifeGame/NutriLife_normal_sin_ropa/NutriLife_normal_sin_ropa/`. La chef está en `nutrilifeGame/chef/chef/`, con la misma estructura y además una animación exclusiva, `chef_celebration`:

- Cada acción tiene una carpeta con `frames/` (6 PNG de 512×512), un **spritesheet** `<acción>.png` de 3072×512 (los 6 cuadros en una fila, de izquierda a derecha y sin margen), un GIF de vista previa y un `animation.json` con fps, loop y eventos por cuadro.
- Acciones disponibles: `idle`, `eat`, `sleep`, `wake`, `curiosity`, `idea`, `sadness`, `happiness`, `jump`, `look_around`, `healthy_recovery`, `interaction_special`.
- `previews/sequence_review_*.jpg` muestran todas las secuencias de un vistazo.

**En la app solo se copian los spritesheets que se usan, convertidos a WebP sin pérdida.** Tienen los mismos píxeles que el PNG original, alfa incluido (se comprobó píxel a píxel), y pesan un 39 % menos: las 7 nutrias pasaron de 13,0 MB a 7,9 MB, unos 0,5–0,7 MB por spritesheet. Flutter decodifica WebP en Android e iOS sin nada extra. Los cuadros sueltos sumados pesan más, así que no se usan.

Para convertir una nutria nueva (necesita Pillow):

```python
from PIL import Image, ImageChops
src = Image.open('nutrilifeGame/pirata/pirata/idle/idle.png').convert('RGBA')
src.save('nutrilife/assets/game/otters/pirata/idle.webp', 'WEBP', lossless=True, method=6, exact=True)
# Comprueba que no cambió ningún píxel:
back = Image.open('nutrilife/assets/game/otters/pirata/idle.webp').convert('RGBA')
assert ImageChops.difference(src, back).getbbox() is None
```

`exact=True` conserva también el color de los píxeles transparentes; quitarlo no ahorra casi nada (528 KB contra 527 KB).

**Qué nutrias entran:** solo las que traen `idle` y `happiness` completos (6 cuadros de 512×512). Las de `nutrilifeGame/NutriLife_Pending_Exclusive_Animations_5/pending_exclusives/` (oro, diamante, dragón de bayas, guardián del bosque y piloto cósmico) solo tienen su animación exclusiva, así que todavía no se pueden sumar.

Para agregar una animación nueva (por ejemplo `sleep`) a todas las nutrias:

1. Convierte a WebP (ver arriba) el `<acción>.png` de cada nutria y déjalo en `nutrilife/assets/game/otters/<id>/<acción>.webp`. Todas las nutrias del catálogo deben tenerla, porque la pantalla arma la ruta igual para cualquiera.
2. Agrega un getter en `OtterSkin`, junto a `idleSheet` y `happinessSheet`: `String get sleepSheet => 'assets/game/otters/$id/sleep.webp';`.

### Lugares, foco y globo

El origen está en `nutrilifeGame/fondos/habitads/`: 16 fondos (`fondo_<lugar>_dia.png` y `_noche.png`; la habitación de día se llama `fondo_habitat_vacio.png`), el foco (`foco_colgante_encendido.png` y `_apagado.png`) y el globo (`globo_dialogo_vacio.png`). **Ya se usa todo lo de esa carpeta.** Los originales pesan muchísimo (5–7 MB cada fondo, unos 100 MB en total), así que en la app van optimizados (6,3 MB en total):

- **Fondos → WebP con pérdida, calidad 88 (200–630 KB cada uno).** Son opacos y tienen cientos de miles de colores: sin pérdida no bajan casi nada. A calidad 88 no se notan diferencias, y pesan un 40 % menos que un JPG de la misma calidad (bosque de día: JPG 730 KB, WebP 430 KB).
- **Foco y globo → recortados al contenido y reducidos a 1/4 con vecino más cercano.** Cada "píxel" del arte medía unos 24–32 px, así que siguen nítidos. Los dos focos se recortan con la misma caja, para que no salten al prenderlo o apagarlo.

Se generaron con Pillow:

```python
from PIL import Image
# Fondos (el id de la habitación es "habitacion"; su original de día es fondo_habitat_vacio.png)
Image.open('fondo_bosque_dia.png').convert('RGB').save('bosque_dia.webp', 'WEBP', quality=88, method=6)
# Foco: misma caja para los dos estados, 1/4 con NEAREST, sin pérdida
box = (228, 104, 1310, 2190)
for state in ('encendido', 'apagado'):
    im = Image.open(f'foco_colgante_{state}.png').crop(box)
    im.resize((im.width // 4, im.height // 4), Image.NEAREST).save(f'foco_{state}.webp', 'WEBP', lossless=True, method=6)
# Globo
b = Image.open('globo_dialogo_vacio.png')
c = b.crop(b.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox())
c.resize((c.width // 4, c.height // 4), Image.NEAREST).save('globo_dialogo.png', optimize=True)
```

Si cambias el foco o el globo, actualiza sus proporciones (`521 / 270` en `_lampHeight`, `304 / 454` en `_bubbleHeight`).

`nutrilifeGame/fondos/isla flotante/` (bóveda, refugio de cristal, nutrias elementales) no es parte de `habitads` y no se usa.

## Colección de nutrias (`OtterSkin`)

Cada nutria (o "traje") es un `OtterSkin` con un `id` y un `label` traducido. **Sus sprites se encuentran por convención**: `assets/game/otters/<id>/idle.webp` y `happiness.webp`. Así la pantalla no sabe qué nutria está mostrando; solo usa `_skin.idleSheet` y `_skin.happinessSheet`.

- `OtterSkin.all` es el catálogo, en el orden en que se muestra la colección.
- `OtterSkin.byId(id)` devuelve la nutria guardada, o la normal si el id ya no existe (por ejemplo, si se quitó una del catálogo). Nunca falla.
- `GamePreferences` guarda el `id` en `shared_preferences` con la clave `game_otter_skin`. `OtterPetScreen` la lee en `initState`. Mientras carga, `_skin` es `null` y la nutria no se dibuja, para no mostrar por un instante otra nutria.
- La hoja (botón 👕, tooltip "Cambiar de nutria") es `showGamePickerSheet`, la misma que usan los lugares. Muestra cada nutria con su cuadro 0 y marca la elegida. Usa `isScrollControlled` y llega como máximo al 85 % del alto; con muchas opciones, el resto hace scroll. Al tocar una, la pantalla la cambia, reinicia el contador de caricias y la guarda.
- La tarjeta de Inicio sigue mostrando la nutria normal (`OtterSkin.normal`), sin importar cuál esté elegida.

### Cuadro de caricia (`petFrame`)

Mientras la acaricias, la nutria muestra un cuadro fijo de su `idle` con los ojos cerrados. **No es el mismo en todas**, aunque el `animation.json` de todas diga `"2": "parpadeo"`:

| Nutria | `petFrame` |
| --- | --- |
| Clásica, Chef, Deportiva | 2 (valor por defecto) |
| Alien menta, Explorador RPG | 1 |
| Corredor arcade | 3 |
| Galaxia | 0: ningún cuadro de su `idle` cierra los ojos |

Para elegirlo, mira los 6 cuadros de su `idle.png` original en `nutrilifeGame/` (o `previews/sequence_review_1.jpg`) y toma el de ojos cerrados con sonrisa.

### Cómo agregar otra nutria (por ejemplo, una `pirata` futura)

1. Convierte a WebP sin pérdida sus spritesheets `nutrilifeGame/pirata/pirata/idle/idle.png` y `.../happiness/happiness.png`, y déjalos en `nutrilife/assets/game/otters/pirata/` como `idle.webp` y `happiness.webp` (ver "Assets").
2. Registra la carpeta en `pubspec.yaml`: `- assets/game/otters/pirata/`. Flutter no incluye subcarpetas solo, así que cada nutria va en su propia línea. Si te olvidas, falla `otter_skin_test.dart`.
3. Agrega el nombre en `lib/l10n/app_es.arb` y `app_en.arb` (`"gameSkinPirata": "Pirata"`) y corre `flutter gen-l10n`.
4. Créala en `OtterSkin` con su `petFrame` si no es 2, y súmala a `all`:
   ```dart
   static final pirata = OtterSkin._('pirata', (l) => l.gameSkinPirata, petFrame: 1);
   static final all = [normal, chef, /* ... */ pirata];
   ```

No hay que tocar la pantalla ni la hoja: aparece sola en la colección.

### Lo que falta para que sea "coleccionar" de verdad

Hoy todas las nutrias del catálogo están disponibles. Para que haya que conseguirlas:

- Agregar al usuario un conjunto de nutrias **obtenidas**: guardarlo junto a la elegida y, si se compran o se ganan, mejor en el backend, para que sigan a la cuenta y no al teléfono (ver el `shortcut:` en `game_preferences.dart`; aplica igual a los lugares).
- Mostrar en la hoja las que faltan con candado o en silueta y no dejar elegirlas.
- Decidir cómo se ganan: rachas, metas cumplidas o PRO.
- Animaciones exclusivas como `chef_celebration`: agregar a `OtterSkin` un campo opcional con la ruta y usarla en `_celebrate()` cuando exista.

## Lugares y día/noche (`HabitatScene`)

Cada lugar es un `HabitatScene` con un `id`, un `label` traducido y `hasLamp`. Sus fondos se encuentran por convención: `assets/game/habitat/<id>_dia.webp` y `<id>_noche.webp`.

- `HabitatScene.all` es el catálogo, en el orden de la hoja "Lugares". `HabitatScene.byId(id)` vuelve a la habitación si el id no existe.
- `GamePreferences` guarda el lugar con la clave `game_habitat`. Como la nutria, `_scene` es `null` hasta leerlo, y el fondo no se dibuja antes.
- **Día o noche:** `_night` empieza con `HabitatScene.isNightAt(DateTime.now())`, que da noche desde las 19:00 hasta las 5:59. El botón de sol/luna lo invierte, pero no se guarda: al volver a entrar se sigue la hora otra vez.
- **Foco:** solo en los lugares con `hasLamp` (hoy, la habitación). `_lampOn` empieza prendido de noche y apagado de día, y se reinicia al cambiar día/noche. Tocar el foco lo prende o lo apaga. De noche y apagado, una capa negra al 55 % (`0x8C000000`) oscurece el fondo y la nutria; el foco, la pista y el globo quedan encima, así que se siguen viendo.
- La hoja "Lugares" muestra cada lugar en la versión que se está viendo (día o noche). Usa `cacheWidth: 276` para no decodificar 16 imágenes de 1440×2560 solo para miniaturas.
- **El piso es el mismo en todos:** se probó la nutria al 87 % del alto en los 8 lugares, con proporciones de teléfono, y queda parada en el suelo en todos (alfombra, sendero, piedras, terraza, plataforma). Si un lugar nuevo tiene el piso en otra altura, hay que agregar a `HabitatScene` un campo con su proporción y usarlo en `otterTop`.

### Cómo agregar otro lugar (por ejemplo, `playa_tropical`)

1. Convierte sus dos fondos a WebP calidad 88 (ver "Lugares, foco y globo") y déjalos como `assets/game/habitat/playa_tropical_dia.webp` y `_noche.webp`. Tienen que medir 1440×2560 (lo comprueba `habitat_scene_test.dart`).
2. Agrega el nombre en los ARB (`"gamePlacePlayaTropical": "Playa tropical"`) y corre `flutter gen-l10n`.
3. Créalo en `HabitatScene` y súmalo a `all`: `static final playaTropical = HabitatScene._('playa_tropical', (l) => l.gamePlacePlayaTropical);`. Si es bajo techo y quieres el foco, pasa `hasLamp: true`.

No hay que tocar `pubspec.yaml`, porque `assets/game/habitat/` ya está registrada, ni la pantalla.

## Cómo se dibuja un cuadro (`OtterSprite`)

La hoja es 6 veces más ancha que alta. Dentro de una caja cuadrada, `BoxFit.cover` la escala a la altura de la caja, y la `Alignment` horizontal elige qué parte del ancho se ve:

```text
alignment.x = -1 + 2 * frame / 5      // frame 0 → -1 (izquierda), frame 5 → 1 (derecha)
```

Flutter (`paintImage`) recorta exactamente esa franja de la imagen original, así que no hace falta `ClipRect` ni `CustomPainter`. `gaplessPlayback: true` evita un parpadeo al cambiar de hoja.

## Composición de la pantalla

La pantalla se **bloquea en vertical** mientras está abierta (`SystemChrome.setPreferredOrientations` en `initState`, y se libera en `dispose`). La escena se calcula con proporciones de un teléfono en vertical: de lado o en una tablet, la nutria no caería sobre la alfombra y el globo saldría de la pantalla.

`OtterPetScreen` dibuja todo en un `Stack` a pantalla completa. Usa `extendBodyBehindAppBar` con un `AppBar` transparente, así que el fondo también queda detrás del título.

**Barra de arriba:** el botón de volver, el título y los tres botones (lugar, día/noche y nutria) van sobre blanco al 85 % (`_onScene`): los botones con `IconButton.styleFrom(backgroundColor: ...)` y el título en `_pill`. Sin eso, los íconos oscuros no se veían sobre los fondos con mucho detalle. El botón de volver es propio (`BackButtonIcon` + `Navigator.maybePop`) porque el de `AppBar` no admite fondo.

Las capas, de abajo hacia arriba:

1. **Fondo** del lugar (día o noche), con `BoxFit.cover`, `Alignment.bottomCenter` y `gaplessPlayback` para que no quede un hueco en blanco al cambiar. En un teléfono (más alto que 9:16) se escala por la altura y recorta los costados, así que cada altura de la imagen cae a la misma proporción de la pantalla.
2. **Nutria** (280×280) centrada, con los pies (~95 % del cuadro) en el suelo (~87 % del alto de la pantalla): `otterTop = alto * 0.87 - 280 * 0.95`.
3. **Oscuridad** (solo de noche con el foco apagado): capa negra al 55 % con `IgnorePointer`, para que se pueda seguir acariciando.
4. **Foco** (96 de ancho), colgado desde el borde de arriba al 25 % del ancho, entre el botón de volver y el título. Tiene `Semantics` de botón ("Prender la luz" / "Apagar la luz").
5. **Pista** "Acaricia a la nutria con el dedo" en una píldora blanca abajo, sobre el área segura.
6. **Globo** "¡Le encantó! 💚", que aparece los 2 s siguientes a `_celebrate()`. Su punta (abajo, a ~25 % de su ancho) toca la cabeza de la nutria, y su `left` se limita para que no se salga en pantallas angostas. Aparece con un rebote (`Curves.easeOutBack` en 250 ms) y se desvanece en los últimos 300 ms; las dos cosas se calculan a partir de `_now`, sin otro controlador. El texto va centrado en el 86 % de arriba del globo, que es el cuerpo; el resto es la punta.

## Bucle de animación

Un solo `Ticker` hace `setState` en cada frame de pantalla (60 fps) y guarda el tiempo transcurrido en `_now`. **El sprite no cambia a 60 fps**: el cuadro se calcula a partir de `_now` y los fps de cada estado. Esos 60 fps solo mueven con suavidad los corazones y la escala.

Estados (getter `_sprite`), en orden de prioridad:

| Estado | Cuándo | Qué se ve |
| --- | --- | --- |
| Feliz | Durante `_happyDuration` después de `_celebrate()` | `happiness`, cuadros 0→5 a `_happyFps` (6 fps), una sola vez |
| Acariciada | Hubo roce en los últimos `_strokeGrace` (150 ms) | `idle`, cuadro `petFrame` fijo (ojos cerrados y sonrisa) y escala 0,96 |
| Reposo | El resto del tiempo | `idle`, cuadro 0 quieto durante `_idleRestMs` (3,5 s); luego la secuencia completa una vez a `_idleFps` (6 fps) |

**Por qué estos fps y no los del `animation.json`** (8 y 10 fps): los 6 cuadros de cada acción son todos un poco distintos. En bucle continuo la nutria parecía hiperactiva o temblorosa. Por eso en reposo se queda quieta y solo de vez en cuando parpadea y mueve las orejas.

## El gesto de acariciar

Está en `_onPointerMove`:

1. El `Listener` envuelve la caja de la nutria (280×280). Solo recibe el movimiento de un dedo que **empezó** sobre ella.
2. Se ignora el 15 % de cada borde (`deflate`) porque el sprite tiene margen transparente. Así solo cuenta el roce sobre el cuerpo.
3. Cada evento suma `e.delta.distance` (píxeles lógicos recorridos) a dos contadores:
   - `_sinceHeart`: cada `_heartEvery` (60 px) sale un corazón en la posición del dedo, con una vibración suave (`selectionClick`).
   - `_petDistance`: al llegar a `_petsToHappy` (900 px, unas 4 o 5 pasadas) se llama a `_celebrate()`. Eso dispara la animación de alegría, 8 corazones, una vibración fuerte (`mediumImpact`) y el globo "¡Le encantó! 💚" durante 2 s. Después el contador vuelve a 0.
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
| `_lampWidth` | Tamaño del foco |
| `HabitatScene.isNightAt` | Desde qué hora es de noche |

Para ver un cambio: hot reload (`r`) en `flutter run`. Si un `static const` no se actualiza, usa hot restart (`R`).

## Tests

`test/features/game/otter_skin_test.dart` comprueba que cada nutria del catálogo tiene sus dos spritesheets declarados en `pubspec.yaml` y que se decodifican a 3072×512, que su `petFrame` está entre 0 y 5, que no hay ids repetidos y que un id desconocido vuelve a la Clásica.

`test/features/game/habitat_scene_test.dart` comprueba que cada lugar tiene su fondo de día y de noche y que se decodifican a 1440×2560, que los dos focos existen, que no hay ids repetidos, que un id desconocido vuelve a la habitación y el borde de la regla día/noche (5:59 noche, 6:00 día, 18:59 día, 19:00 noche).

`test/features/game/otter_pet_screen_test.dart` comprueba que:

- acariciar con el dedo saca corazones y, tras varias pasadas, muestra "¡Le encantó! 💚";
- los toques sin mover el dedo no cuentan;
- elegir la Chef en "Tu colección" la muestra, la guarda y sigue elegida al volver a entrar, sin mostrar antes la Clásica;
- elegir "Costa" en "Lugares" cambia el fondo, lo guarda, no muestra el foco (no es bajo techo) y el botón de sol/luna pasa a la versión de día;
- de noche, apagar el foco oscurece la habitación y prenderlo la aclara.

Como la escena empieza de día o de noche según la hora real, los tests que dependen de eso primero tocan "Ver de noche" si hace falta (`goToNight`).

Los tests buscan la nutria por `find.byType(OtterSprite)`. Después de `pumpWidget` hace falta un `pump()` para que lea la nutria guardada, porque antes no hay nutria dibujada. Para abrir la hoja hace falta `pump()` y luego `pump(500 ms)`: no se puede usar `pumpAndSettle` porque el `Ticker` nunca se detiene.

```bash
flutter test test/features/game
```

## Lo que falta / ideas para continuar

- **Persistencia del estado:** hoy solo se guardan la nutria y el lugar elegidos. Para un tamagotchi real faltan estados (cariño, hambre, energía) guardados con `shared_preferences` (ya está en la app) o en el backend, y que bajen con el tiempo.
- **Más interacciones** con las otras acciones: dar de comer (`eat`, con la comida como objeto aparte, ver el README de assets y la carpeta `nutrilifeGame/comida`), dormir/despertar (`sleep` se reproduce una vez y se queda en el último cuadro; luego `wake`), tristeza si la descuidas (`sadness`), etc.
- **Dormir:** de noche con el foco apagado sería el momento natural para la animación `sleep` (y `wake` al prenderlo o al llegar el día).
- **Más nutrias:** ya están todas las de `nutrilifeGame/` que tienen animaciones. Faltan las de `pending_exclusives` (cuando lleguen sus `idle` y `happiness`). `nutrias_vestimenta` y `nutrias_desbloqueables` son imágenes de referencia sueltas, sin animaciones.
- **Más fondos:** ya se usan todos los de `habitads`. Falta `fondos/isla flotante/`, que trae otras piezas (bóveda, refugio de cristal) y no tiene versión día/noche.
- **¿Flame?** Hoy no hace falta: con una sola nutria, un gesto y un fondo, Flutter puro alcanza y no suma dependencias. Conviene pasarse a [Flame](https://flame-engine.org/) (motor 2D sobre Flutter: game loop, `SpriteAnimation`, colisiones, cámara, audio) si el juego llega a tener varios objetos que se mueven y chocan (comida que cae, minijuegos, mundo con cámara). [Flutter Scene](https://fscene.dev/) es para 3D, así que no aplica a este pixel art.
- **Separar la lógica** si el juego crece: hoy todo el estado vive en el `State` de la pantalla. Con más estados conviene moverlo a una clase propia (por ejemplo un `ChangeNotifier`, como `core/state/` en el resto de la app) para probarlo sin widgets.
