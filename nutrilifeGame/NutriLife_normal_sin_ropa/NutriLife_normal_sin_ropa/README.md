# NutriLife — animaciones base (nutria normal, sin ropa)

Este paquete contiene únicamente la apariencia básica de la nutria, sin vestuario ni accesorios. Se conserva el diseño pixel art, la paleta y las proporciones de la referencia; los ojos quedan negros, sin blanco.

## Uso en el juego

- Cada acción contiene 6 cuadros de **512×512 px** y un spritesheet PNG de **3072×512 px**.
- Los cuadros del spritesheet van de izquierda a derecha, sin margen ni separación; `frame_000` es el primero y `frame_005` el último.
- Los PNG conservan canal alfa. Los GIF son vistas previas.
- `animation.json` por acción indica FPS, loop, duración y eventos. `manifest.json` reúne todos los metadatos.
- En `eat` y `healthy_recovery` no hay comida dibujada: el juego debe mostrar y mover el alimento como objeto independiente.
- `sleep` muestra la transición gradual: bajar el cuerpo, agacharse, sentarse, recostarse y quedar dormida. Es una acción de una sola reproducción; mantener el último cuadro mientras duerme.

## Acciones

`idle`, `eat`, `sleep`, `wake`, `curiosity`, `idea`, `sadness`, `happiness`, `jump`, `look_around`, `healthy_recovery`, `interaction_special`.

Las hojas de revisión en `previews/` muestran cada secuencia de seis cuadros en orden.
