# Edita el export de n8n para que el chat acepte alimentos adjuntos.
# Se hace por script porque los nodos Code guardan JS escapado dentro del JSON
# y editarlo a mano rompe el flujo con facilidad.
import io
import json

PATH = 'n8n/NutriAI - Chat de Recetas.json'
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

// Adjuntar un alimento no debe tumbar la receta en curso: si el usuario pidio
// modificarla o pregunto por ella, esa intencion gana sobre los adjuntos.
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
  // Cada guard degrada a una ruta que si puede responder, en vez de romper.
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
    // El chef nombra lo pedido a partir de ingredients; con adjuntos sale de ahi.
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

# 4. Salida nueva del switch. Se agrega al final para no correr los indices de
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
#    el backend ya resolvio los foodId reales.
if 'Usar Alimentos Adjuntos' not in nodes:
    base = nodes['Reusar Alimentos de Receta Previa']['position']
    flow['nodes'].append({
        'parameters': {
            'jsCode': '''// Los adjuntos ya vienen con foodId y cantidad resueltos por el backend,
// asi que el pool del chef se arma sin pasar por /food/match.
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
#    El switch tiene fallbackOutput "extra", o sea una salida de más al final
#    que va a Chat General. La regla nueva se INSERTA antes de esa salida; si se
#    escribiera sobre el último índice se pisaría el fallback.
conexiones = flow['connections']
salidas = conexiones['Enrutar por Intención']['main']
destino = [{'node': 'Usar Alimentos Adjuntos', 'type': 'main', 'index': 0}]
indice_nuevo = len(reglas) - 1
ya_cableado = any(
    conexion and conexion[0]['node'] == 'Usar Alimentos Adjuntos'
    for conexion in salidas
)
if not ya_cableado:
    salidas.insert(indice_nuevo, destino)

conexiones['Usar Alimentos Adjuntos'] = {
    'main': [[{'node': 'Preparar Contexto del Chef', 'type': 'main', 'index': 0}]]
}

io.open(PATH, 'w', encoding='utf-8', newline='\n').write(
    json.dumps(flow, ensure_ascii=False, indent=2)
)
print('workflow actualizado')
