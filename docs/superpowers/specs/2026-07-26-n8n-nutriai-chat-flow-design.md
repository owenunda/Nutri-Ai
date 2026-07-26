# Diseño: Flujo de chat NutriAI en n8n

Fecha: 2026-07-26
Estado: aprobado

## Problema

El workflow `NutriAI - Recetas IA MVP` solo atiende un caso: generar una receta cuando el
usuario nombra ingredientes. El nodo interpretador de intención reconoce siete intents, pero
la rama de conversación del router está vacía y el resto cae por defecto en "generar receta".
Además el flujo falla en el segundo mensaje de cualquier usuario.

### Defectos detectados

| # | Nodo | Defecto |
|---|---|---|
| 1 | `Flow Router` | Rama TRUE (CONVERSATION) vacía: `MODIFY_RECIPE` y `ASK_RECIPE` dejan el webhook colgado |
| 2 | `Decide Flow` | Lee `$json.hasActiveSession`, que `parse intent` no propaga; siempre `undefined` |
| 3 | `Create Chat Session` | Hace POST siempre; el backend responde 409 si ya hay sesión activa |
| 4 | `Update Conversation State` | Lee `intent` de `Normalize Session`, donde no existe |
| 5 | `Decide Flow` | `GENERAL_CHAT` y `UNKNOWN` caen en `NEW_RECIPE`: un "hola" dispara receta + YouTube |
| 6 | backend | `last_intent` solo admite 5 valores; `GENERAL_CHAT`/`UNKNOWN` son rechazados |
| 7 | `HTTP Request` | `GENERATE_RECIPE_FROM_FRIDGE` llega con `ingredients: []`; la nevera nunca se consulta |
| 8 | `parse3` | `items[0]` sin guard: si YouTube no devuelve nada se pierde la receta entera |
| 9 | huérfanos | `Guardar receta` y el bloque `Webhook Confirm` apuntan a `localhost:3000` y a `/recipes/:id/execute`, que no existe |
| 10 | `YOUTUBE` | API key de Google escrita en el JSON |
| 11 | ` Parse Media` | Nombre con espacio inicial; reutiliza el parser de recetas y mapea `ingredients_used` sobre una respuesta que no los tiene |

## Contratos del backend

Verificados contra el código, no contra la documentación.

- `GET /api/v1/chat/session` → `{ data: { hasActiveSession, session? } }`
- `POST /api/v1/chat/session` → 201 con la sesión, **409** si ya existe una activa
- `PUT /api/v1/chat/session` → reemplaza `conversation_state`; el validador **descarta**
  cualquier campo raíz fuera de `recipe`, `media`, `last_intent`, `metadata`
- `POST /api/v1/chat/session/message` → `{ role: USER|ASSISTANT, content }`, 404 sin sesión
- `POST /api/v1/food/match` → `{ ingredients: [{name, quantity}] }` → `data: [{foodId, name, caloriesPerUnit, baseUnit, quantity}]`
- `GET /api/v1/fridge` → `data.items: [{fridgeItemId, name, quantity, unit}]` — **sin `foodId`**
- `last_intent` válido: `GENERATE_RECIPE_WITH_INPUT`, `GENERATE_RECIPE_FROM_FRIDGE`,
  `MODIFY_RECIPE`, `ASK_RECIPE`, `NEW_RECIPE`, o `null`
- `metadata.meal_type` válido: `desayuno`, `almuerzo`, `cena`, o `null`

## Arquitectura

Tronco común → `Switch` de 6 rutas → convergencia en un nodo de respuesta.

### Tronco común

```
Webhook: Mensaje de Chat
  → Extraer Datos del Request        (userId, message, userName, authToken)
  → Obtener Sesión Activa            GET /chat/session
  → ¿Tiene Sesión Activa?            IF
       NO → Crear Sesión de Chat     POST /chat/session
  → Unificar Datos de Sesión         Code: normaliza la forma de GET y de POST
  → Guardar Mensaje del Usuario      POST /chat/session/message  role=USER
  → Agente: Interpretar Intención
  → Parsear Intención                arrastra los datos de sesión
  → Resolver Ruta                    aplica los guards
  → Enrutar por Intención            SWITCH
```

### Rutas

| Salida | `route` | Condición | Camino |
|---|---|---|---|
| 0 | `RECIPE_FROM_INPUT` | `GENERATE_RECIPE_WITH_INPUT` con ingredientes | Mapear Ingredientes a Alimentos |
| 1 | `RECIPE_FROM_FRIDGE` | `GENERATE_RECIPE_FROM_FRIDGE`, o intent de receta sin sesión | Obtener Nevera → Extraer Ingredientes → Mapear |
| 2 | `MODIFY_RECIPE` | `MODIFY_RECIPE` con receta en sesión | Agente: Modificar Receta |
| 3 | `ANSWER_QUESTION` | `ASK_RECIPE` con receta en sesión | Agente: Responder Pregunta |
| 4 | `NEW_RECIPE_SAME_POOL` | `NEW_RECIPE` con receta en sesión | Reusar Alimentos de Receta Previa |
| 5 | `GENERAL_CHAT` | `GENERAL_CHAT`, `UNKNOWN`, fallback | Agente: Chat General |

Los guards degradan en vez de romper: modificar sin sesión genera una receta nueva desde la
nevera; preguntar sin receta activa cae en chat general.

### Convergencia

```
Mapear Ingredientes a Alimentos  ─┐
Reusar Alimentos Receta Previa   ─┴→ Preparar Contexto del Chef
                                      → Agente: Chef de Cocina
                                      → Parsear Receta del Chef
                                          ├→ Agente: Búsqueda de Video → Parsear Consulta
                                          │   → Buscar Video en YouTube → Extraer Datos del Video ─┐
                                          └──────────────────────────────→ Combinar Receta y Video ┘

Combinar Receta y Video       ─┐
Parsear Receta Modificada     ─┤
Parsear Respuesta de Consulta ─┼→ Construir Respuesta Final
Parsear Respuesta de Chat     ─┤
Respuesta: Nevera Vacía       ─┘
     → ¿Requiere Guardar Receta?   IF
          SÍ → Actualizar Estado de Conversación   PUT /chat/session
     → Guardar Respuesta del Bot   POST /chat/session/message  role=ASSISTANT
     → Responder al Usuario
```

Un solo `Agente: Chef de Cocina` sirve a las tres rutas de generación; recibe `avoidTitle`,
vacío salvo en `NEW_RECIPE_SAME_POOL`.

## Decisiones

### `available_foods` viaja dentro de `recipe`

El validador del backend descarta campos raíz desconocidos pero guarda `recipe` completo.
El pool de alimentos matcheados se persiste como `recipe.available_foods` para que
`MODIFY_RECIPE` y `NEW_RECIPE` reutilicen los `foodId` sin volver a llamar a `/food/match`.
Sin esto, modificar una receta perdería los ingredientes que el usuario tipeó a mano.

Alternativa descartada: agregar `available_foods` al validador del backend. Más limpio, pero
toca código de producción para un beneficio equivalente.

### `NEW_RECIPE` reutiliza el pool anterior

Se le pasa al chef el mismo `available_foods` del turno previo más el título a evitar. Si no
hay sesión previa o el pool está vacío, degrada a `RECIPE_FROM_FRIDGE`.

### El tipo de respuesta lo declara cada rama

Cada nodo de parseo emite `responseType`. `Construir Respuesta Final` lee ese campo en vez de
volver a consultar `route`, para no acoplar la construcción de la respuesta al enrutamiento.

### Solo se persiste el estado cuando hay receta

`ANSWER` y `CHAT` no hacen `PUT`. El validador convierte los campos ausentes en `null`, así que
un `PUT` en esas rutas borraría la receta guardada.

## Manejo de errores

- `Buscar Video en YouTube` con `onError: continueRegularOutput`; `Extraer Datos del Video`
  verifica `items?.length` y devuelve `media: null`. Una cuota agotada no tumba la receta.
- Los cinco nodos de parseo de LLM recortan desde el primer `{` hasta el último `}` y, si
  fallan, lanzan un error que incluye el texto crudo.
- `Crear Sesión de Chat` y los dos nodos de historial usan `onError: continueRegularOutput`.
- El `Switch` tiene salida de fallback hacia `GENERAL_CHAT`.
- `Parsear Receta del Chef` descarta los `food_id` que no estén en el pool: el modelo no puede
  inventar identificadores.
- `last_intent` y `meta.meal_type` se sanean contra las listas que acepta el backend.
- Nevera vacía: `¿Nevera con Alimentos?` desvía a una respuesta de chat en vez de llamar al chef.

## Contrato de respuesta

```json
{
  "type": "RECIPE | RECIPE_MODIFIED | ANSWER | CHAT",
  "message": "texto para la burbuja del chat",
  "recipe": { "...": "o null" },
  "media":  { "youtube": { "...": "o null" } },
  "session": { "sessionId": 1, "version": 2 }
}
```

## Fuera de alcance

- El bloque huérfano de confirmación de receta (`Webhook Confirm` y sus cinco nodos) se elimina.
  Apuntaba a `localhost:3000` y a `/recipes/:id/execute`, que no existe. Si se necesita
  confirmación de recetas, va en su propio workflow contra `/recipes/:id/action`.
- La API key de YouTube se deja literal en el nodo por decisión del autor. Conviene rotarla:
  ya estuvo expuesta en el archivo exportado.
