# Progreso funcional: registro de comidas, peso, semana y Premium (visual)

Fecha: 2026-10-12
Estado: diseño aprobado por partes en conversación; pendiente revisión del spec escrito.

## Problema

La pantalla de Progreso ya lee datos reales del backend, pero casi todo sale en cero o vacío porque la app no tiene forma de registrar lo que se come:

- El **+** de cada alimento (`FoodListTile`) solo muestra un SnackBar; no guarda nada.
- "Comidas de hoy" en Inicio (`dashboard_screen.dart`, `MealCard`) es texto fijo, y sus **+** no hacen nada.
- El backend tiene `POST /meals` y `POST /meals/:id/items`, pero ninguna ruta para leer comidas, y la base no distingue desayuno/almuerzo/cena.
- El peso solo se guarda al editar el perfil; no hay un "Registrar peso".
- "PROGRESO SEMANAL" es solo una etiqueta: todo lo que se muestra es de hoy, y la gráfica de "Resumen de peso" es decorativa.
- El backend calcula "hoy" en UTC (`toISOString().split('T')[0]`), así que lo que se come de noche cae en el día siguiente.
- `POST /meals/:id/items` no verifica que el registro pertenezca al usuario.

## Alcance

Entra:

1. Registrar comidas con tipo (desayuno, almuerzo, cena, snack) y porciones, y borrarlas.
2. "Comidas de hoy" con datos reales, detalle por comida e historial por día.
3. Registrar peso desde Progreso.
4. Tarjeta "Esta semana" (kcal de 7 días contra la meta) y "Resumen nutricional" semanal.
5. Pantalla Premium solo visual, sin cobro ni bloqueo de funciones.

No entra:

- "Agregar al log diario" de las recetas del chat. Las cantidades de sus ingredientes vienen en la unidad de la nevera, no en porciones del alimento; necesita su propio diseño.
- Pagos reales y bloqueo de funciones Premium.
- Unificar la fórmula de calorías que hoy está duplicada en backend y app (se usa la del backend vía `/stats`).

## Parte 1: datos y backend

### Base de datos

Script nuevo `backend/src/database/backups/update_12_10_2026_meals.sql`:

```sql
ALTER TABLE meal_record_details
    ADD COLUMN IF NOT EXISTS meal_type VARCHAR(10) NOT NULL DEFAULT 'SNACK'
    CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'));

-- Un solo registro por usuario y día (hoy solo lo garantiza el servicio).
CREATE UNIQUE INDEX IF NOT EXISTS uq_meal_records_user_date
    ON meal_records (user_id, record_date);
```

- El tipo vive en cada línea (`meal_record_details`), no en `meal_records`: se conserva "un registro por día" que el servicio ya implementa, y lo existente queda como `SNACK`.
- Antes de crear el índice único hay que comprobar que no existan duplicados (usuario, fecha); si los hay, el script debe fusionarlos moviendo sus detalles al registro más antiguo.

### Rutas

Todas bajo `/api/v1`, autenticadas.

| Ruta | Cambio | Contrato |
|---|---|---|
| `POST /meals` | Sin cambio de contrato | `{ date? }` → registro del día (busca o crea). La app siempre manda `date` local. |
| `POST /meals/:id/items` | Acepta `meal_type` por ítem; **verifica que el registro sea del usuario** (404 si no) | `[{ food_id, quantity, meal_type }]`; `meal_type` por defecto `SNACK`; `quantity` > 0 en porciones de la unidad base. |
| `GET /meals/day?date=YYYY-MM-DD` | **Nueva** | `{ date, totalCalories, meals: { BREAKFAST: { totalCalories, items: [...] }, LUNCH, DINNER, SNACK } }`; cada ítem `{ detailId, foodId, name, baseUnit, quantity, calories }`. Día sin registro → todas las comidas vacías y total 0. |
| `DELETE /meals/items/:detailId` | **Nueva** | Borra el ítem si pertenece al usuario; 404 si no existe o no es suyo. Devuelve el ítem borrado (para "Deshacer"). |
| `GET /stats/week?end=YYYY-MM-DD` | **Nueva** | `{ start, end, dailyLimit, days: [{ date, totalConsumed }] x7, average, daysOnTarget }`. Días sin registros → 0. `dailyLimit` con la misma lógica de `/stats/consumption-validation`; null si faltan datos físicos. `daysOnTarget` cuenta días con consumo > 0 y ≤ meta. |
| `GET /stats/today-calories`, `GET /stats/consumption-validation` | Aceptan `?date=` | Si llega, se usa en vez de la fecha UTC del servidor. |
| `POST /user/physical` | Sin cambio | `{ height, weight }`, ambos obligatorios. |

Las calorías de un ítem son `foods.calories_per_unit * quantity`, como ya calcula `stats.repository.js`.

## Parte 2: registrar comidas (app)

### Hoja "Agregar a tu día"

Se abre desde el **+** de `FoodListTile` (pantalla Alimentos y "Todos los alimentos") y desde el flujo de "Comidas de hoy".

- Encabezado con emoji y nombre del alimento.
- Chips Desayuno · Almuerzo · Cena · Snack. Preselección por hora local: antes de 11:00 Desayuno, antes de 16:00 Almuerzo, si no Cena. Si se abrió desde una comida concreta, viene esa marcada.
- Porciones con − / + de 0,5 en 0,5 (mín. 0,5, máx. 10); por defecto 1.
- Texto en vivo: "1½ porciones · 150 g · 144 kcal". Si la unidad base empieza con un número y G/ML, se multiplica (100 G × 1,5 = 150 g); si no ("1 UNIDAD"), se muestra "1½ unidad".
- Botón "Agregar a {comida}". Flujo: `POST /meals {date}` → `POST /meals/:id/items`.
- Al guardar: SnackBar "Agregado a Almuerzo · 144 kcal" con **Deshacer** (llama al DELETE).
- Error: la hoja queda abierta con el mensaje; el botón se habilita de nuevo.

### "Comidas de hoy" en Inicio

- Cuatro tarjetas (Desayuno, Almuerzo, Cena, Snack) desde `GET /meals/day`. Descripción: nombres de los alimentos separados por coma (recortada) y total de kcal, o "Aún no registrada".
- **+** de una tarjeta: abre la lista de alimentos en modo selección; elegir uno abre la hoja con esa comida marcada.
- Tocar la tarjeta: hoja con los alimentos de esa comida (nombre, porciones, kcal) y 🗑 por ítem.
- "Ver historial": pantalla "Historial de comidas" con ◀ fecha ▶ (no permite ir más allá de hoy) que reutiliza la vista por día.
- Estados: cargando (esqueleto), error con "Reintentar".

### Sincronización

Un notificador compartido (patrón `BotMoodState`/`DioClient.rateLimit`) incrementa una revisión cada vez que se agrega o borra una comida o un peso. Inicio y Progreso lo escuchan y recargan; así el resumen se actualiza sin pull-to-refresh.

## Parte 3: Progreso

### Registrar peso

- Botón "Registrar peso" en la tarjeta "Resumen de peso".
- Hoja con el último peso precargado, − / + de 0,1 kg o escritura directa; rango 30–300 kg.
- Envía `POST /user/physical` con la altura del perfil. Si el perfil no tiene altura, la hoja pide también la altura.
- La gráfica decorativa (`_InsightChartPainter`) se reemplaza por una mini línea con los últimos pesos (hasta 7). Con menos de 2 registros no se dibuja.

### "Esta semana"

- Tarjeta nueva desde `GET /stats/week?end=<hoy local>`.
- Barras de los 7 días con iniciales (L M M J V S D) según la fecha real; hoy resaltado; línea punteada en la meta diaria; barras sobre la meta en ámbar.
- Tocar una barra muestra "Mié 8 · 1.920 kcal".
- Pie: "Promedio: 1.850 kcal/día · 4 de 7 días en tu meta". Sin meta (faltan datos físicos): solo el promedio y un enlace "Completa tu perfil".

### "Resumen nutricional"

Pasa a semanal con los datos de `/stats/week`: Promedio diario · Meta diaria · Días en meta · Total de la semana. "Calorías de hoy" queda como está y pasa a mostrar consumo real (`?date=` local).

## Parte 4: Premium (visual)

- Entradas: fila "NutriLife Premium" en Perfil y una tarjeta discreta al final de Progreso ("Desbloquea tu progreso completo").
- Pantalla: nutria arriba, título "NutriLife Premium", lista de beneficios (chef IA sin límite de mensajes, historial de progreso completo, planes de comida semanales, recetas guardadas sin límite), dos planes seleccionables (Mensual $4.99; Anual $29.99 · "Ahorra 50%", preseleccionado), botón "Empezar 7 días gratis", pie "Restaurar compras · Términos".
- El botón y el pie muestran "Los pagos llegan pronto"; nada cobra ni se bloquea. Precios y textos son de ejemplo y quedan en constantes fáciles de cambiar.

## Orden de despliegue

1. Script SQL en la base (antes que el backend: el backend nuevo lee `meal_type`).
2. Push del backend.
3. App.

## Pruebas

- Backend: no hay suite de tests. Cada consulta nueva se valida con `EXPLAIN` en transacción de solo lectura contra la base, y las rutas se prueban con llamadas reales tras el despliegue.
- App (tests de widget y de repositorio con adaptador falso de Dio):
  - Hoja de agregar: preselección por hora, porciones (mín./máx., texto "150 g · 144 kcal" y unidad no numérica), llamada con `meal_type` y `date` local.
  - Deshacer llama al DELETE.
  - "Comidas de hoy": pinta lo que devuelve `/meals/day`, "Aún no registrada", borrar ítem.
  - Historial: ◀ ▶ cambia la fecha y no pasa de hoy.
  - Registrar peso: rango, precarga, pide altura si falta.
  - "Esta semana": iniciales de días, promedio y días en meta, caso sin meta.
  - Premium: elegir plan y el aviso de "pronto".
  - Notificador: agregar/borrar dispara recarga en Inicio y Progreso.
