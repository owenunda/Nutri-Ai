# Alimentos adjuntos en el chat

Fecha: 2026-08-30

## Problema

El selector de la nevera ya funciona: el usuario elige alimentos con el botón `+`
y se adjuntan al mensaje. Pero hoy se adjuntan **como texto**, agregando una línea
`Tengo estos alimentos: Banana, Pera.` al final del mensaje.

Eso tiene dos defectos:

1. **El chef recibe menos información de la que existe.** El texto solo lleva
   nombre y cantidad. n8n tiene que re-extraer los nombres con un LLM y volver a
   buscarlos con `POST /food/match`, cuando la app ya tenía el `foodId` exacto,
   las calorías y la unidad base.
2. **Ensucia la conversación.** La burbuja del usuario muestra una frase que él
   no escribió.

## Objetivo

Que los alimentos elegidos viajen como **datos estructurados** hasta el chef de
n8n, y que en la interfaz se vean como etiquetas dentro de la burbuja, no como
texto inventado dentro del mensaje.

Las dos mitades son inseparables: si se quita la línea de texto sin mandar los
datos aparte, el mensaje `"necesito un desayuno"` clasifica como
`GENERATE_RECIPE_FROM_FRIDGE` y el flujo barre la nevera completa, ignorando la
selección.

## Fuera de alcance

- Recargar el historial de mensajes dentro del chat (queda para después). Hoy
  `ChatHistoryDrawer` solo lista sesiones y nunca repinta mensajes viejos, así
  que las etiquetas son estado local de la sesión en curso y no se persisten.
- Editar cantidades desde el selector.

## Contrato

### App → backend

```
POST /api/v1/n8n/chat
{
  "message": "necesito un desayuno",
  "fridgeItemIds": [4, 7]
}
```

Se mandan `fridgeItemIds` y no `foodIds` porque el item de nevera es el que
carga `quantity` y `unit`, y es inequívoco por usuario. `message` viaja limpio.

`fridgeItemIds` es opcional; sin él, el comportamiento actual del chat no cambia.

### Backend → n8n

```json
{
  "message": "...",
  "userId": 1,
  "name": "...",
  "token": "...",
  "attachedFoods": [
    {
      "fridgeItemId": 4,
      "foodId": 11,
      "name": "Banana",
      "quantity": 1,
      "unit": "unidad",
      "caloriesPerUnit": 89,
      "baseUnit": "100 G"
    }
  ]
}
```

La forma de cada elemento es un superconjunto de lo que hoy devuelve
`POST /food/match`, que es lo que el chef ya sabe consumir.

## Decisiones

### El backend resuelve los ids, no la app

La app manda solo ids; el backend los relee de la nevera **del usuario
autenticado** antes de pasarlos a n8n. Un id que no pertenezca a esa nevera
simplemente no aparece en el resultado.

Importa porque el `foodId` que el chef devuelve en `ingredients_used` termina
escrito en `recipe_ingredients`. Dejar que el cliente dicte esos ids sería
confiar en datos no verificados para una escritura en base.

### Cantidad 0 viaja como 1

Los alimentos creados desde la pantalla Alimentos entran a la nevera con
`quantity = 0` (`addItemToFridgeService`). El prompt del chef ordena *"nunca una
cantidad mayor a la disponible"*, así que un 0 literal le prohíbe usar el
alimento — que es exactamente lo contrario de lo que el usuario pidió al
adjuntarlo.

`matchFoods` ya resuelve esto con `quantity: ingredient.quantity ?? 1`. Se
replica esa regla: cantidad 0 o nula viaja como 1.

### La intención del usuario gana sobre los adjuntos

Si hay adjuntos y la intención es de generación (`GENERATE_RECIPE_WITH_INPUT`,
`GENERATE_RECIPE_FROM_FRIDGE`, `NEW_RECIPE`, `UNKNOWN`), se usa la selección.

Si la intención es `MODIFY_RECIPE` o `ASK_RECIPE` sobre una receta activa, esa
intención manda y los adjuntos se ignoran. Adjuntar un alimento no debe tumbar
la receta en curso.

### Se elimina `message_composer.dart`

Era la solución de la iteración anterior. Con los datos viajando aparte, componer
texto deja de tener sentido. Se borran el archivo y sus tests.

## Componentes

### Backend

- `findFridgeItemsByIdsRepository(userId, ids)` — mismo JOIN que
  `getFridgeByUserIdRepository`, filtrado por `fi.fridge_item_id = ANY($2)` y
  `fr.user_id = $1`.
- `getFridgeItemsByIdsService(userId, ids)` — normaliza a enteros, descarta
  basura, aplica el tope de 20 elementos y la regla de cantidad 0 → 1.
- Handler `/n8n/chat` — lee `fridgeItemIds`, resuelve, pasa `attachedFoods` a
  `sendChatN8n`.
- `sendChatN8n(message, userId, userName, token, attachedFoods)` — agrega el
  campo al payload del webhook.

### n8n

El workflow modificado se entrega como archivo en `n8n/`; el usuario lo
reemplaza en su instancia. Cuatro nodos:

1. **Extraer Datos del Request** (Set) — nueva asignación `attachedFoods` desde
   `$json.body.attachedFoods`, con `[]` por defecto.
2. **Agente: Interpretar Intención** — el prompt recibe la lista de adjuntos como
   contexto, para que no clasifique a ciegas.
3. **Resolver Ruta** (Code) — aplica la regla de precedencia y produce la ruta
   nueva `RECIPE_FROM_ATTACHED`, poblando `ingredients` desde los adjuntos.
4. **Enrutar por Intención** (Switch) — salida nueva hacia un nodo Code
   `Usar Alimentos Adjuntos`, que emite `{availableFoods: [...]}` y conecta
   directo a `Preparar Contexto del Chef`. Ese nodo ya acepta esa forma sin
   cambios, y se ahorra la llamada a `/food/match`.

### App

- `FridgeItemModel` — ya tiene los campos necesarios.
- `ChatMessageModel` — gana `attachedFoods` para pintar las etiquetas.
- `ChatRepository.sendMessage(message, {fridgeItemIds})`.
- `ChatViewModel.sendMessage(text, {foods})`.
- `ChatInputField.onSend` pasa a `(String message, List<FridgeItemModel> foods)`.
- `_ChatBubble` — bajo el texto del usuario, una fila de pills blancas
  translúcidas sobre el verde de la burbuja, con nombre y cantidad.

## Errores

- **Ids que no son del usuario**: se descartan en silencio. El mensaje se envía
  igual, sin esos alimentos. No es un caso que el usuario pueda provocar desde la
  interfaz.
- **`fridgeItemIds` ausente o vacío**: el chat se comporta como hoy.
- **Falla la consulta de nevera**: el error sube por el manejador de errores
  existente de `/n8n/chat`; el mensaje no se envía a medias.

## Pruebas

En la app, TDD como hasta ahora: el payload que arma `ChatRepository`, el
`ChatViewModel` guardando los adjuntos en el mensaje, y la burbuja pintando una
pill por alimento.

El backend no tiene runner de tests (`npm test` está sin configurar). Montar uno
está fuera del alcance de este cambio, así que la consulta nueva se verifica
llamando al endpoint con el servidor levantado. Queda anotado como deuda.
