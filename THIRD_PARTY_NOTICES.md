# Avisos de terceros

## Bloub

El motor de animacion del bot en `nutriapp/lib/features/bot/domain/bot_engine.dart`
y `nutriapp/lib/features/bot/domain/bot_eyes.dart`, y los datos de
`nutriapp/lib/features/bot/data/bot_profiles.dart`, portan lo siguiente desde
[Bloub](https://github.com/jeremy-prt/bloub):

- **La tecnica**: perfiles radiales muestreados (un array de radios alrededor
  de la silueta) e interpolados con una spline Catmull-Rom de tension 1/6.
- **Las constantes de pose y ojos** medidas del video original de Bloub
  (`face.ts`, `decor.ts`): tamano y separacion de los ojos, orientacion de la
  mirada en reposo, duracion del parpadeo, posiciones y radio de los tres
  puntos de "pensando", y su factor de pico.
- **Las constantes de timing** de los estados portados (`states.ts`):
  duracion y tiempo de transicion ("morph") de `idle` y `thinking`, y la
  formula de rebote de `sleep`.

Las formulas anteriores (incluidas `spin`, el calculo de las poses de ojo en
reposo y `dotPulse`) son transliteraciones linea a linea del TypeScript
original, portadas a Dart puro (sin `dart:ui` ni `package:flutter`). No se
extrajeron los perfiles radiales `egg`, `hexagon` ni `triangle` de Bloub:
quedan fuera del alcance de esta funcionalidad.

Bloub se distribuye bajo la siguiente licencia:

```
MIT License

Copyright (c) 2026 Jérémy Perret

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
