# Alimentos adjuntos en el chat — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que los alimentos elegidos en el selector de la nevera viajen como datos estructurados hasta el chef de n8n, y que en la burbuja del chat se vean como etiquetas en vez de texto inventado dentro del mensaje.

**Architecture:** La app manda `fridgeItemIds` en el body de `POST /n8n/chat`. El backend los relee de la nevera del usuario autenticado y arma `attachedFoods` para el webhook. n8n enruta a `RECIPE_FROM_ATTACHED` y alimenta al chef directo, sin pasar por `/food/match`. En la app, el mensaje guarda su lista de alimentos y la burbuja los pinta como pills.

**Tech Stack:** Flutter/Dart (app, `dio`, `flutter_test`), Node/Express + Postgres (backend, ESM), n8n (workflow exportado como JSON en el repo).

**Spec:** `docs/superpowers/specs/2026-08-30-alimentos-adjuntos-chat-design.md`

## Global Constraints

- Todo el texto visible al usuario va en español.
- No se agregan dependencias nuevas ni al backend ni a la app.
- Los comentarios explican el **porqué**, nunca el qué; en español, como el resto del repo.
- El backend no tiene runner de tests (`npm test` sin configurar). Las tareas de backend se verifican ejecutando código real, no con tests automatizados.
- La app sí va con TDD: test que falla primero, y se verifica que falle antes de implementar.
- El workflow de n8n se entrega como archivo modificado en `n8n/NutruLife - Chat de Recetas.json`. **Nadie toca la instancia de n8n**; el usuario reemplaza el flujo él mismo.
- Cantidad 0 o nula viaja siempre como `1` (el prompt del chef trata la cantidad como límite superior).

---

### Task 1: El backend resuelve los ids contra la nevera del usuario

**Files:**
- Modify: `backend/src/modules/fridge/fridge.repository.js`
- Modify: `backend/src/modules/fridge/fridge.service.js`
- Modify: `backend/src/utils/n8n.service.js`
- Modify: `backend/src/app.js:100-113`

**Interfaces:**
- Consumes: nada de tareas anteriores.
- Produces:
  - `findFridgeItemsByIdsRepository(userId: number, fridgeItemIds: number[]) → Promise<Array<{fridgeItemId, foodId, name, quantity, unit, caloriesPerUnit, baseUnit}>>`
  - `getFridgeItemsByIdsService(userId: number, fridgeItemIds: unknown) → Promise<Array<...>>` (misma forma, con `quantity` ya normalizada a `>= 1`)
  - `sendChatN8n(message, userId, userName, token, attachedFoods = [])`
  - Body aceptado por `POST /api/v1/n8n/chat`: `{ message: string, fridgeItemIds?: number[] }`

- [ ] **Step 1: Agregar la consulta al repositorio**

Al final de `backend/src/modules/fridge/fridge.repository.js`:

```js
// Solo los items de la nevera del propio usuario: un id ajeno simplemente no
// aparece en el resultado. Esa es la garantía que sostiene todo el adjunto,
// porque el foodId que devuelva el chef termina escrito en recipe_ingredients.
export const findFridgeItemsByIdsRepository = async (userId, fridgeItemIds) => {
    const query = `
        SELECT
            fi.fridge_item_id   AS "fridgeItemId",
            f.food_id           AS "foodId",
            f.name              AS "name",
            fi.quantity         AS "quantity",
            fi.unit             AS "unit",
            f.calories_per_unit AS "caloriesPerUnit",
            f.base_unit         AS "baseUnit"
        FROM fridge_items fi
        JOIN fridges fr ON fr.fridge_id = fi.fridge_id
        JOIN foods f ON f.food_id = fi.food_id
            AND f.is_active = true
            AND (f.is_global = true OR f.created_by_user_id = $1)
        WHERE fr.user_id = $1
            AND fi.fridge_item_id = ANY($2::int[])
        ORDER BY fi.fridge_item_id
    `;

    const { rows } = await pool.query(query, [userId, fridgeItemIds]);
    return rows;
};
```

- [ ] **Step 2: Agregar el servicio**

En `backend/src/modules/fridge/fridge.service.js`, agregar `findFridgeItemsByIdsRepository` al import existente de `./fridge.repository.js` y añadir al final:

```js
const MAX_ATTACHED_FOODS = 20;

// El prompt del chef trata la cantidad como techo ("nunca una cantidad mayor a
// la disponible"), así que un 0 le prohibiría usar el alimento — justo lo
// contrario de lo que pidió el usuario al adjuntarlo. matchFoods ya resuelve
// esto igual, con `quantity ?? 1`.
const normalizeQuantity = (quantity) => {
    const value = Number(quantity);
    return Number.isFinite(value) && value > 0 ? value : 1;
};

export const getFridgeItemsByIdsService = async (userId, fridgeItemIds) => {
    try {
        const ids = (Array.isArray(fridgeItemIds) ? fridgeItemIds : [])
            .map(Number)
            .filter(Number.isInteger)
            .slice(0, MAX_ATTACHED_FOODS);

        if (ids.length === 0) {
            return [];
        }

        const items = await findFridgeItemsByIdsRepository(userId, ids);

        return items.map((item) => ({
            ...item,
            quantity: normalizeQuantity(item.quantity),
            caloriesPerUnit: Number(item.caloriesPerUnit),
        }));
    } catch (error) {
        if (error instanceof AppError) {
            throw error;
        }

        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};
```

- [ ] **Step 3: Pasar los adjuntos al webhook**

En `backend/src/utils/n8n.service.js`, cambiar la firma y el payload:

```js
export const sendChatN8n = async (message, userId, userName, token, attachedFoods = []) => {
  try {
    const payload = {
      message,
      userId,
      name: userName,
      token,
      attachedFoods,
    };
    const response = await axios.post(URL_WEBHOOK, payload);
    return response.data;
  } catch (error) {
    console.error("Error al enviar mensaje a n8n:", error.response?.data || error.message);
    throw new AppError("Error al comunicarse con el servicio de chat", 500, "N8N_ERROR");
  }
}
```

- [ ] **Step 4: Resolver los ids en el handler**

En `backend/src/app.js`, agregar el import junto a los demás:

```js
import { getFridgeItemsByIdsService } from './modules/fridge/fridge.service.js';
```

Y reemplazar el cuerpo del handler (`app.js:100-113`) por:

```js
app.post('/api/v1/n8n/chat', authenticateToken(['ADMIN', 'USER']), chatRateLimit, async (req, res) => {
  try {
    const { message, fridgeItemIds } = req.body;
    const { userId, name } = req.user;
    const token = req.headers.authorization?.split(" ")[1];

    if (!message) throw new AppError("Bad request", 400, "BAD_REQUEST");

    // Los ids se releen de la nevera del usuario autenticado: lo que el cliente
    // mande y no sea suyo nunca llega a n8n.
    const attachedFoods = await getFridgeItemsByIdsService(userId, fridgeItemIds);

    const result = await sendChatN8n(message, userId, name, token, attachedFoods);
    return successResponse(res, result, 'Mensaje enviado correctamente a n8n');
  } catch (error) {
    errorResponse(res, error.message, error.code, error.status, error.details);
  }
});
```

- [ ] **Step 5: Verificar que los módulos cargan**

Run: `cd backend && node --check src/modules/fridge/fridge.repository.js && node --check src/modules/fridge/fridge.service.js && node --check src/app.js`
Expected: sin salida de error.

- [ ] **Step 6: Verificar la consulta contra la base**

Con el backend levantado (`npm run dev`) y un token válido en `$TOKEN`, sacar un `fridgeItemId` real:

```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/v1/fridge
```

Luego mandar un mensaje adjuntando ese id:

```bash
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"message":"necesito un desayuno","fridgeItemIds":[4]}' http://localhost:3000/api/v1/n8n/chat
```

Expected: responde 200. En los logs de n8n, el body del webhook trae `attachedFoods` con `foodId`, `caloriesPerUnit` y `quantity >= 1`.

Si no hay base a mano, dejar constancia de que este paso quedó sin ejecutar en vez de darlo por bueno.

- [ ] **Step 7: Commit**

```bash
git add backend/src/modules/fridge/fridge.repository.js backend/src/modules/fridge/fridge.service.js backend/src/utils/n8n.service.js backend/src/app.js
git commit -m "feat(backend): resolver alimentos adjuntos de la nevera para n8n"
```

---

### Task 2: El workflow de n8n consume los adjuntos

**Files:**
- Modify: `n8n/NutruLife - Chat de Recetas.json`

**Interfaces:**
- Consumes: el campo `attachedFoods` que Task 1 agrega al payload del webhook.
- Produces: ruta `RECIPE_FROM_ATTACHED` y nodo `Usar Alimentos Adjuntos`, que emite `{availableFoods: [{foodId, name, caloriesPerUnit, baseUnit, quantity}]}` hacia `Preparar Contexto del Chef` (ese nodo ya acepta esa forma; no se toca).

El JSON es un export de n8n: editarlo con un script en vez de a mano, para no romper el escapado de los `jsCode`.

- [ ] **Step 1: Escribir el script de migración del workflow**

Crear `scripts/n8n_adjuntos.py`:

```python
# Edita el export de n8n para que el chat acepte alimentos adjuntos.
# Se hace por script porque los nodos Code guardan JS escapado dentro del JSON
# y editarlo a mano rompe el flujo con facilidad.
import io, json

PATH = 'n8n/NutruLife - Chat de Recetas.json'
flow = json.load(io.open(PATH, encoding='utf-8'))
nodes = {n['name']: n for n in flow['nodes']}

# 1. El webhook ya recibe attachedFoods; hay que exponerlo como campo del flujo.
extraer = nodes['Extraer Datos del Request']
asignaciones = extraer['parameters']['assignments']['assignments']
if not any(a['name'] == 'attachedFoods' for a in asignaciones):
    asignaciones.append({
        'id': 'f1a0c7d2-0005-4a11-9f01-0a1b2c3d4e05',
        'name': 'attachedFoods',
        'value': '={{ $json.body.attachedFoods ?? [] }}',
        'type': 'array',
    })

# 2. El agente de intención clasificaba a ciegas: el mensaje ya no nombra los
#    alimentos, así que hay que decírselos aparte.
intencion = nodes['Agente: Interpretar Intención']
contenido = intencion['parameters']['responses']['values'][0]['content']
bloque = (
    "\n## Alimentos adjuntos\n\n"
    "{{ $('Extraer Datos del Request').first().json.attachedFoods.length "
    "? 'El usuario adjuntó estos alimentos de su nevera: ' + "
    "$('Extraer Datos del Request').first().json.attachedFoods.map(f => f.name).join(', ') + "
    "'. Trátalos como los alimentos que el usuario menciona.' "
    ": 'El usuario no adjuntó alimentos.' }}\n"
)
if '## Alimentos adjuntos' not in contenido:
    marca = '## Intenciones'
    contenido = contenido.replace(marca, bloque + '\n' + marca, 1)
    intencion['parameters']['responses']['values'][0]['content'] = contenido

# 3. Los adjuntos mandan solo cuando el usuario quiere generar.
nodes['Resolver Ruta']['parameters']['jsCode'] = '''const j = $input.first().json;
const attached = $('Extraer Datos del Request').first().json.attachedFoods ?? [];

const hasRecipe = Boolean(j.previousRecipe && j.previousRecipe.title);
const hasIngredients = Array.isArray(j.ingredients) && j.ingredients.length > 0;
const hasPool = Array.isArray(j.availableFoods) && j.availableFoods.length > 0;
const hasAttached = Array.isArray(attached) && attached.length > 0;

// Adjuntar un alimento no debe tumbar la receta en curso: si el usuario pidió
// modificarla o preguntó por ella, esa intención gana sobre los adjuntos.
const INTENCIONES_DE_GENERACION = [
  'GENERATE_RECIPE_WITH_INPUT',
  'GENERATE_RECIPE_FROM_FRIDGE',
  'NEW_RECIPE',
  'UNKNOWN'
];

let route;
if (hasAttached && INTENCIONES_DE_GENERACION.includes(j.intent)) {
  route = 'RECIPE_FROM_ATTACHED';
} else {
  // Cada guard degrada a una ruta que sí puede responder, en vez de romper.
  switch (j.intent) {
    case 'GENERATE_RECIPE_WITH_INPUT':
      route = hasIngredients ? 'RECIPE_FROM_INPUT' : 'RECIPE_FROM_FRIDGE';
      break;

    case 'GENERATE_RECIPE_FROM_FRIDGE':
      route = 'RECIPE_FROM_FRIDGE';
      break;

    case 'MODIFY_RECIPE':
      route = hasRecipe ? 'MODIFY_RECIPE' : 'RECIPE_FROM_FRIDGE';
      break;

    case 'ASK_RECIPE':
      route = hasRecipe ? 'ANSWER_QUESTION' : 'GENERAL_CHAT';
      break;

    case 'NEW_RECIPE':
      route = (hasRecipe && hasPool) ? 'NEW_RECIPE_SAME_POOL' : 'RECIPE_FROM_FRIDGE';
      break;

    default:
      route = 'GENERAL_CHAT';
  }
}

return [{
  json: {
    ...j,
    route,
    attachedFoods: attached,
    // El chef nombra lo pedido a partir de ingredients; con adjuntos sale de ahí.
    ingredients: route === 'RECIPE_FROM_ATTACHED'
      ? attached.map(f => ({
          name: String(f.name).toLowerCase().trim(),
          quantity: f.quantity ?? null
        }))
      : j.ingredients,
    // Si el usuario no repite el tipo de comida, se hereda del turno anterior.
    mealType: j.mealType ?? j.previousMealType ?? null
  }
}];'''

# 4. Salida nueva del switch. Se agrega al final para no correr los índices de
#    las salidas existentes, que ya tienen conexiones.
switch = nodes['Enrutar por Intención']
reglas = switch['parameters']['rules']['values']
if not any(r.get('outputKey') == 'Receta con Adjuntos' for r in reglas):
    reglas.append({
        'conditions': {
            'options': {
                'caseSensitive': True,
                'leftValue': '',
                'typeValidation': 'strict',
                'version': 2,
            },
            'conditions': [{
                'id': 's6a0c7d2-3007-4a11-9f01-0a1b2c3d4e37',
                'leftValue': '={{ $json.route }}',
                'rightValue': 'RECIPE_FROM_ATTACHED',
                'operator': {'type': 'string', 'operation': 'equals'},
            }],
            'combinator': 'and',
        },
        'renameOutput': True,
        'outputKey': 'Receta con Adjuntos',
    })

# 5. Nodo nuevo: el pool sale directo de los adjuntos, sin /food/match, porque
#    el backend ya resolvió los foodId reales.
if 'Usar Alimentos Adjuntos' not in nodes:
    base = nodes['Reusar Alimentos de Receta Previa']['position']
    flow['nodes'].append({
        'parameters': {
            'jsCode': '''// Los adjuntos ya vienen con foodId y cantidad resueltos por el backend,
// así que el pool del chef se arma sin pasar por /food/match.
const attached = $json.attachedFoods ?? [];

return [{
  json: {
    availableFoods: attached.map(f => ({
      foodId: f.foodId,
      name: f.name,
      caloriesPerUnit: f.caloriesPerUnit,
      baseUnit: f.baseUnit,
      quantity: f.quantity
    }))
  }
}];'''
        },
        'type': 'n8n-nodes-base.code',
        'typeVersion': 2,
        'position': [base[0], base[1] + 220],
        'id': 'a7c15e90-0007-4a11-9f01-0a1b2c3d4e07',
        'name': 'Usar Alimentos Adjuntos',
    })

# 6. Cablear: switch (salida nueva) -> nodo nuevo -> contexto del chef.
conexiones = flow['connections']
salidas = conexiones['Enrutar por Intención']['main']
destino = [{'node': 'Usar Alimentos Adjuntos', 'type': 'main', 'index': 0}]
if len(salidas) < len(reglas):
    salidas.append(destino)
else:
    salidas[len(reglas) - 1] = destino

conexiones['Usar Alimentos Adjuntos'] = {
    'main': [[{'node': 'Preparar Contexto del Chef', 'type': 'main', 'index': 0}]]
}

io.open(PATH, 'w', encoding='utf-8', newline='\\n').write(
    json.dumps(flow, ensure_ascii=False, indent=2)
)
print('workflow actualizado')
```

- [ ] **Step 2: Ejecutar el script**

Run: `cd "C:/Users/owenu/OneDrive/Desktop/Personal/Nutri-Ai" && python scripts/n8n_adjuntos.py`
Expected: imprime `workflow actualizado`.

- [ ] **Step 3: Verificar el workflow resultante**

```bash
python -c "
import json,io
d=json.load(io.open('n8n/NutruLife - Chat de Recetas.json',encoding='utf-8'))
nodes={n['name']:n for n in d['nodes']}
assert any(a['name']=='attachedFoods' for a in nodes['Extraer Datos del Request']['parameters']['assignments']['assignments'])
assert 'RECIPE_FROM_ATTACHED' in nodes['Resolver Ruta']['parameters']['jsCode']
assert 'Usar Alimentos Adjuntos' in nodes
salidas=d['connections']['Enrutar por Intención']['main']
assert salidas[-1][0]['node']=='Usar Alimentos Adjuntos', salidas[-1]
assert d['connections']['Usar Alimentos Adjuntos']['main'][0][0]['node']=='Preparar Contexto del Chef'
sw=nodes['Enrutar por Intención']
reglas=sw['parameters']['rules']['values']
tiene_fallback = sw['parameters'].get('options',{}).get('fallbackOutput')=='extra'
assert len(salidas)==len(reglas)+(1 if tiene_fallback else 0), (len(reglas),len(salidas))
for regla,salida in zip(reglas,salidas):
    print(' ',regla['outputKey'],'->',salida[0]['node'])
print('  (fallback) ->',salidas[-1][0]['node'])
"
```

Expected: 6 reglas, cada una apuntando a su nodo, y `(fallback) -> Agente: Chat General`.

**El switch tiene `fallbackOutput: "extra"`**: una salida de más al final, sin regla asociada, que va a Chat General. Por eso hay una salida más que reglas, y por eso la ruta nueva se **inserta** antes de la última en vez de escribirse sobre ella — escribir sobre el último índice pisa el fallback y deja el chat general muerto.

- [ ] **Step 4: Commit**

```bash
git add "n8n/NutruLife - Chat de Recetas.json" scripts/n8n_adjuntos.py
git commit -m "feat(n8n): ruta RECIPE_FROM_ATTACHED para alimentos adjuntos"
```

Al terminar, avisar al usuario que el archivo está listo para que lo reemplace en su instancia de n8n.

---

### Task 3: La app manda los ids en el body

**Files:**
- Modify: `nutrilife/lib/features/chatbot/data/chat_repository.dart:47-58`
- Test: `nutrilife/test/features/chatbot/chat_repository_test.dart`

**Interfaces:**
- Consumes: el body `{message, fridgeItemIds}` que acepta Task 1.
- Produces: `ChatRepository.sendMessage(String message, {List<int> fridgeItemIds = const []})`

- [ ] **Step 1: Escribir el test que falla**

En `nutrilife/test/features/chatbot/chat_repository_test.dart`, agregar un adaptador que capture el body y los tests, al final del archivo:

```dart
/// Captura el body de la petición para poder afirmar sobre lo que se envía.
class _CapturingAdapter implements HttpClientAdapter {
  Object? capturedBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedBody = options.data;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'type': 'CHAT', 'message': 'hola', 'recipe': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void _mainAdjuntos() {
  group('ChatRepository.sendMessage con adjuntos', () {
    late _CapturingAdapter adapter;
    late ChatRepository repo;

    setUp(() {
      adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      repo = ChatRepository(dio: dio);
    });

    test('manda los ids de los alimentos adjuntos', () async {
      await repo.sendMessage('necesito un desayuno', fridgeItemIds: [4, 7]);

      expect((adapter.capturedBody as Map)['fridgeItemIds'], [4, 7]);
    });

    test('omite el campo cuando no hay adjuntos', () async {
      await repo.sendMessage('hola');

      expect((adapter.capturedBody as Map).containsKey('fridgeItemIds'), isFalse);
    });

    test('sigue mandando el mensaje tal cual', () async {
      await repo.sendMessage('necesito un desayuno', fridgeItemIds: [4]);

      expect((adapter.capturedBody as Map)['message'], 'necesito un desayuno');
    });
  });
}
```

Y llamar `_mainAdjuntos();` desde el `main()` existente del archivo.

- [ ] **Step 2: Verificar que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_repository_test.dart`
Expected: FALLA con `No named parameter with the name 'fridgeItemIds'`.

- [ ] **Step 3: Implementar**

En `nutrilife/lib/features/chatbot/data/chat_repository.dart`:

```dart
  Future<ChatResponse> sendMessage(
    String message, {
    List<int> fridgeItemIds = const [],
  }) async {
    final Response<Map<String, dynamic>> response;

    try {
      response = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.n8nChat,
        data: {
          'message': message,
          // El backend los relee de la nevera; aquí solo viajan los ids.
          if (fridgeItemIds.isNotEmpty) 'fridgeItemIds': fridgeItemIds,
        },
        options: Options(
          receiveTimeout: _chatTimeout,
          sendTimeout: _chatTimeout,
        ),
      );
```

El resto del método queda igual.

- [ ] **Step 4: Verificar que pasa**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_repository_test.dart`
Expected: PASA, incluidos los tests que ya existían.

- [ ] **Step 5: Commit**

```bash
git add nutrilife/lib/features/chatbot/data/chat_repository.dart nutrilife/test/features/chatbot/chat_repository_test.dart
git commit -m "feat(app): mandar fridgeItemIds al enviar un mensaje"
```

---

### Task 4: El mensaje recuerda sus alimentos

**Files:**
- Modify: `nutrilife/lib/features/chatbot/data/models/chat_message_model.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart:45-60`
- Test: `nutrilife/test/features/chatbot/chat_view_model_test.dart` (crear)

**Interfaces:**
- Consumes: `ChatRepository.sendMessage(message, {fridgeItemIds})` de Task 3; `FridgeItemModel` de `features/nutrition/data/models/fridge_item_model.dart`.
- Produces:
  - `ChatMessageModel(..., List<FridgeItemModel> attachedFoods = const [])`
  - `ChatViewModel.sendMessage(String text, {List<FridgeItemModel> foods = const []})`

- [ ] **Step 1: Escribir el test que falla**

Crear `nutrilife/test/features/chatbot/chat_view_model_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:nutrilife/features/nutrition/data/models/fridge_item_model.dart';

/// Responde siempre un CHAT vacío y recuerda el body recibido.
class _CapturingAdapter implements HttpClientAdapter {
  Object? capturedBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedBody = options.data;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'type': 'CHAT', 'message': 'listo', 'recipe': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _banana = FridgeItemModel(
  fridgeItemId: 4,
  foodId: 11,
  name: 'Banana',
  quantity: 0,
  unit: 'unidad',
  caloriesPerUnit: 89,
  baseUnit: '100 G',
);

void main() {
  late _CapturingAdapter adapter;
  late ChatViewModel viewModel;

  setUp(() {
    adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    viewModel = ChatViewModel(repository: ChatRepository(dio: dio));
  });

  tearDown(() => viewModel.dispose());

  test('guarda los alimentos adjuntos en el mensaje del usuario', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect(viewModel.messages.first.attachedFoods.single.name, 'Banana');
  });

  test('no mete los alimentos dentro del texto del mensaje', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect(viewModel.messages.first.text, 'necesito un desayuno');
  });

  test('manda los ids de los adjuntos al repositorio', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect((adapter.capturedBody as Map)['fridgeItemIds'], [4]);
  });

  test('envía aunque el texto venga vacío si hay alimentos', () async {
    await viewModel.sendMessage('  ', foods: [_banana]);

    expect(viewModel.messages, isNotEmpty);
  });

  test('no envía nada sin texto ni alimentos', () async {
    await viewModel.sendMessage('   ');

    expect(viewModel.messages, isEmpty);
  });
}
```

- [ ] **Step 2: Verificar que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_view_model_test.dart`
Expected: FALLA con `No named parameter with the name 'foods'`.

- [ ] **Step 3: Implementar el modelo**

En `nutrilife/lib/features/chatbot/data/models/chat_message_model.dart`, agregar el import de `FridgeItemModel` y el campo:

```dart
import '../../../nutrition/data/models/fridge_item_model.dart';
import 'recipe_model.dart';

class ChatMessageModel {
  final String fullText;
  String displayedText;
  final bool isUser;
  final DateTime timestamp;
  final RecipeModel? recipeData;

  /// Los alimentos que el usuario adjuntó con este mensaje. Viven solo en la
  /// sesión en curso: el historial no repinta mensajes viejos.
  final List<FridgeItemModel> attachedFoods;

  ChatMessageModel({
    required String text,
    required this.isUser,
    required this.timestamp,
    this.recipeData,
    this.attachedFoods = const [],
  })  : fullText = text,
        displayedText = text;

  ChatMessageModel.animating({
    required String text,
    required this.isUser,
    required this.timestamp,
  })  : fullText = text,
        displayedText = '',
        recipeData = null,
        attachedFoods = const [];

  String get text => displayedText;
  bool get isRecipe => recipeData != null;
}
```

- [ ] **Step 4: Implementar el view model**

En `nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart`, agregar el import de `FridgeItemModel` y reemplazar el arranque de `sendMessage`:

```dart
  Future<void> sendMessage(
    String text, {
    List<FridgeItemModel> foods = const [],
  }) async {
    final message = text.trim();
    // Adjuntar alimentos sin escribir nada es una petición válida.
    if (message.isEmpty && foods.isEmpty) return;

    _typingTimer?.cancel();

    _messages.add(ChatMessageModel(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      attachedFoods: foods,
    ));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(
        message,
        fridgeItemIds: foods.map((f) => f.fridgeItemId).toList(),
      );
```

El resto del método (manejo de `reply`, errores y `finally`) queda igual.

- [ ] **Step 5: Verificar que pasa**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_view_model_test.dart`
Expected: PASA los 5 tests.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/chatbot/data/models/chat_message_model.dart nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart nutrilife/test/features/chatbot/chat_view_model_test.dart
git commit -m "feat(app): el mensaje guarda sus alimentos adjuntos"
```

---

### Task 5: Las etiquetas en la burbuja

**Files:**
- Create: `nutrilife/lib/features/chatbot/presentation/widgets/attached_food_chips.dart`
- Delete: `nutrilife/lib/features/chatbot/data/message_composer.dart`
- Delete: `nutrilife/test/features/chatbot/message_composer_test.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/widgets/chat_input_field.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart:96-98` y `:236-273`
- Test: `nutrilife/test/features/chatbot/attached_food_chips_test.dart` (crear)
- Test: `nutrilife/test/features/chatbot/chat_input_field_test.dart` (actualizar)

**Interfaces:**
- Consumes: `ChatMessageModel.attachedFoods` de Task 4.
- Produces: `AttachedFoodChips({required List<FridgeItemModel> foods})`; `ChatInputField.onSend` pasa a `Future<void> Function(String message, List<FridgeItemModel> foods)`.

- [ ] **Step 1: Escribir el test que falla**

Crear `nutrilife/test/features/chatbot/attached_food_chips_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/attached_food_chips.dart';
import 'package:nutrilife/features/nutrition/data/models/fridge_item_model.dart';

const _banana = FridgeItemModel(
  fridgeItemId: 4,
  foodId: 11,
  name: 'Banana',
  quantity: 0,
  unit: 'unidad',
  caloriesPerUnit: 89,
  baseUnit: '100 G',
);

const _arroz = FridgeItemModel(
  fridgeItemId: 5,
  foodId: 12,
  name: 'Arroz',
  quantity: 200,
  unit: 'g',
  caloriesPerUnit: 130,
  baseUnit: '100 G',
);

Future<void> pump(WidgetTester tester, List<FridgeItemModel> foods) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AttachedFoodChips(foods: foods)),
  ));
}

void main() {
  testWidgets('pinta una etiqueta por alimento', (tester) async {
    await pump(tester, [_banana, _arroz]);

    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Arroz · 200 g'), findsOneWidget);
  });

  testWidgets('omite la cantidad cuando no hay', (tester) async {
    await pump(tester, [_banana]);

    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('no pinta nada sin alimentos', (tester) async {
    await pump(tester, []);

    expect(find.byType(Wrap), findsNothing);
  });
}
```

- [ ] **Step 2: Verificar que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/attached_food_chips_test.dart`
Expected: FALLA al no existir `attached_food_chips.dart`.

- [ ] **Step 3: Implementar el widget**

Crear `nutrilife/lib/features/chatbot/presentation/widgets/attached_food_chips.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';

/// Etiquetas de los alimentos adjuntos a un mensaje.
///
/// Van sobre el verde de la burbuja del usuario, así que el contraste se
/// resuelve con blanco translúcido en vez de un color propio.
class AttachedFoodChips extends StatelessWidget {
  final List<FridgeItemModel> foods;

  const AttachedFoodChips({super.key, required this.foods});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: foods.map((food) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                _label(food),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _label(FridgeItemModel food) {
  if (food.quantity <= 0) return food.name;

  final quantity = food.quantity % 1 == 0
      ? food.quantity.toInt().toString()
      : food.quantity.toString();

  return '${food.name} · $quantity ${food.unit}';
}
```

- [ ] **Step 4: Verificar que pasa**

Run: `cd nutrilife && flutter test test/features/chatbot/attached_food_chips_test.dart`
Expected: PASA los 3 tests.

- [ ] **Step 5: Actualizar el test del input**

En `nutrilife/test/features/chatbot/chat_input_field_test.dart`, cambiar las expectativas: `onSend` ahora recibe dos argumentos y el texto viaja limpio.

Reemplazar el primer test por:

```dart
  testWidgets('manda el texto limpio y los alimentos elegidos por separado',
      (tester) async {
    String? sentMessage;
    List<FridgeItemModel>? sentFoods;

    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (message, foods) async {
        sentMessage = message;
        sentFoods = foods;
      },
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hazme una cena');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(sentMessage, 'Hazme una cena');
    expect(sentFoods!.single.name, 'arroz');
  });
```

Y reemplazar entero el test `envía solo los alimentos cuando no se escribe texto` por:

```dart
  testWidgets('envía solo los alimentos cuando no se escribe texto',
      (tester) async {
    String? sentMessage;
    List<FridgeItemModel>? sentFoods;

    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (message, foods) async {
        sentMessage = message;
        sentFoods = foods;
      },
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(sentMessage, '');
    expect(sentFoods!.single.name, 'arroz');
  });
```

En los demás tests del archivo, cambiar las lambdas `onSend: (_) async {}` por `onSend: (_, _) async {}` y `onSend: (_) async => calls++` por `onSend: (_, _) async => calls++`. Agregar el import de `FridgeItemModel`.

- [ ] **Step 6: Verificar que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_input_field_test.dart`
Expected: FALLA al compilar, porque `onSend` todavía recibe un solo argumento.

- [ ] **Step 7: Actualizar el input y borrar el compositor**

En `nutrilife/lib/features/chatbot/presentation/widgets/chat_input_field.dart`: quitar el import de `message_composer.dart`, cambiar la firma y el envío.

```dart
  final Future<void> Function(String message, List<FridgeItemModel> foods) onSend;
```

```dart
  void _handleSend() {
    if (widget.isLoading) return;

    final message = _controller.text.trim();
    final foods = _attachedFoods;
    // Adjuntar alimentos sin escribir nada es una petición válida.
    if (message.isEmpty && foods.isEmpty) return;

    _controller.clear();
    setState(() => _attachedFoods = []);
    widget.onSend(message, foods);
  }
```

Borrar los archivos del compositor:

```bash
git rm nutrilife/lib/features/chatbot/data/message_composer.dart nutrilife/test/features/chatbot/message_composer_test.dart
```

- [ ] **Step 8: Conectar la pantalla**

En `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart`, agregar el import de `FridgeItemModel` y de `attached_food_chips.dart`, y cambiar el handler:

```dart
  Future<void> _handleSend(String message, List<FridgeItemModel> foods) async {
    await _viewModel.sendMessage(message, foods: foods);
    _scrollToBottom();
  }
```

Y en `_ChatBubble`, reemplazar el `child: Text(...)` de la burbuja del usuario por:

```dart
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                if (message.attachedFoods.isNotEmpty) ...[
                  if (message.text.isNotEmpty) const SizedBox(height: 10),
                  AttachedFoodChips(foods: message.attachedFoods),
                ],
              ],
            ),
```

- [ ] **Step 9: Verificar toda la suite**

Run: `cd nutrilife && flutter test`
Expected: todos los tests pasan. `message_composer_test.dart` ya no existe.

Run: `cd nutrilife && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add -A nutrilife
git commit -m "feat(app): mostrar los alimentos adjuntos como etiquetas en la burbuja"
```

---

## Verificación final

- [ ] `cd nutrilife && flutter test` pasa completo.
- [ ] `cd nutrilife && flutter analyze` sin issues.
- [ ] `cd backend && node --check src/app.js` sin errores.
- [ ] El script de validación del Task 2 imprime `flujo OK: 7 rutas`.
- [ ] Avisar al usuario que `n8n/NutruLife - Chat de Recetas.json` está listo para reemplazar en su instancia, y que hasta que lo haga el flujo viejo ignorará `attachedFoods` y generará recetas con la nevera completa.
