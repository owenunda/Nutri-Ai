# Le dice al chef en qué unidad van las cantidades de ingredients_used.
# Sin esto el modelo respondía gramos sin que nada se lo exigiera, y quien
# las consume (la app al registrar la receta) no tenía cómo saberlo.
# Se edita por script, igual que n8n_adjuntos.py, para no romper el JSON.
import io
import json

PATH = 'n8n/NutriLife - Chat de Recetas.json'
flow = json.load(io.open(PATH, encoding='utf-8'))
nodes = {n['name']: n for n in flow['nodes']}

ANCLA = '- En ingredients_used, food_id debe ser exactamente un foodId de la lista de alimentos disponibles.\n'
REGLA = (
    '- En ingredients_used, quantity es la cantidad para TODA la receta (todas las porciones), '
    'en gramos si el baseUnit del alimento está en G, en mililitros si está en ML, y en piezas '
    '(unidades) en cualquier otro caso. Ejemplo: 300 g de pechuga → 300; 2 huevos → 2.\n'
)

for nombre in ('Agente: Chef de Cocina', 'Agente: Modificar Receta'):
    mensaje = nodes[nombre]['parameters']['responses']['values'][0]
    if REGLA in mensaje['content']:
        continue
    assert mensaje['content'].count(ANCLA) == 1, nombre
    mensaje['content'] = mensaje['content'].replace(ANCLA, ANCLA + REGLA)

io.open(PATH, 'w', encoding='utf-8', newline='\n').write(
    json.dumps(flow, ensure_ascii=False, indent=2)
)
