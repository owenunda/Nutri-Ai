# Progreso funcional Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el usuario registre comidas (por tipo y porciones) y peso, vea "Comidas de hoy" reales, un historial por día, su semana de calorías en Progreso, y una pantalla Premium solo visual.

**Architecture:** El tipo de comida se guarda por línea en `meal_record_details.meal_type`; el backend suma rutas de lectura/borrado y una de estadística semanal, y acepta la fecha local del cliente. En la app, un módulo nuevo `features/meals` (dominio, repositorio, hojas y pantallas) es usado por Alimentos, Inicio y Progreso; un notificador global `MealLogState` sincroniza las pantallas tras cada registro.

**Tech Stack:** Node/Express + `pg` (Postgres), Flutter 3 / Dart 3.12, Dio, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-12-progreso-funcional-design.md`

## Global Constraints

- Tipos de comida en la API y la base: exactamente `BREAKFAST`, `LUNCH`, `DINNER`, `SNACK`; por defecto `SNACK`.
- Etiquetas en la app: Desayuno, Almuerzo, Cena, Snack.
- Preselección por hora local: antes de 11:00 Desayuno, antes de 16:00 Almuerzo, si no Cena.
- Porciones: pasos de 0,5; mínimo 0,5; máximo 10; por defecto 1.
- Peso: 30–300 kg, pasos de 0,1. `POST /user/physical` exige `height` y `weight`.
- Fechas entre app y backend: `YYYY-MM-DD` de la fecha **local** del dispositivo.
- Premium: Mensual $4.99, Anual $29.99 "Ahorra 50%" (preseleccionado), botón "Empezar 7 días gratis"; nada cobra ni bloquea, todo muestra "Los pagos llegan pronto".
- Orden de despliegue: SQL → backend → app. El backend se commitea y se hace push a `main` al terminar cada tarea de backend **después** de que el SQL esté aplicado; la app y docs se commitean en local y se suben cuando el usuario lo apruebe.
- Commits sin línea `Co-Authored-By`.
- Código y comentarios en español, siguiendo el estilo de cada archivo (no correr `dart format` sobre archivos existentes: el repo no está formateado y genera ruido).
- Comandos: tests de app con `flutter test <ruta>` desde `nutrilife/`; análisis con `flutter analyze lib test` (el único aviso aceptado es el `unused_import` preexistente en `lib/core/constants/api_base_url.dart`).

---

## File Structure

**Backend (`backend/src/`)**
- `database/backups/update_12_10_2026_meals.sql` — nuevo: `meal_type`, fusión de duplicados, índice único.
- `utils/date.js` — nuevo: `resolveDateParam(value)`.
- `modules/meal/meal.repository.js` — `meal_type` en el insert; `findMealRecordOwnerRepository`, `getDayMealsRepository`, `deleteMealItemRepository`.
- `modules/meal/meal.service.js` — validación de `meal_type`, chequeo de dueño, `getDayMealsService`, `deleteMealItemService`.
- `modules/meal/meal.controller.js`, `meal.routes.js` — `GET /day`, `DELETE /items/:detailId`.
- `modules/stats/stats.repository.js` — `getConsumptionCaloriesByDate(userId, date)`, `getWeekConsumptionRepository(userId, start, end)`.
- `modules/stats/stats.service.js` — `calculateDailyLimit(userData)`, `?date=` en los servicios existentes, `getWeekStatsService`.
- `modules/stats/stats.controller.js`, `stats.routes.js` — `GET /week`, `date` en las existentes.

**App (`nutrilife/lib/`)**
- `core/utils/local_date.dart` — `localDateString`.
- `core/state/meal_log_state.dart` — notificador global.
- `core/network/api_routes.dart` — rutas nuevas.
- `features/meals/domain/meal_type.dart` — enum `MealType`.
- `features/meals/domain/portions.dart` — formato de porciones/cantidades/kcal.
- `features/meals/data/models/day_meals.dart` — `MealItem`, `MealGroup`, `DayMeals`.
- `features/meals/data/meal_repository.dart` — `addFood`, `deleteItem`, `getDay`.
- `features/meals/presentation/widgets/add_food_sheet.dart` — hoja "Agregar a tu día".
- `features/meals/presentation/widgets/meal_detail_sheet.dart` — detalle de una comida con borrar.
- `features/meals/presentation/widgets/day_meals_list.dart` — las 4 tarjetas de un día (usa `MealCard`).
- `features/meals/presentation/screens/meal_history_screen.dart` — ◀ fecha ▶.
- `features/home/presentation/widgets/meal_card.dart` — callbacks `onTap`/`onAdd`.
- `features/home/presentation/widgets/today_meals_section.dart` — "Comidas de hoy" real.
- `features/home/presentation/screens/dashboard_screen.dart` — usa `TodayMealsSection`.
- `features/nutrition/presentation/widgets/food_list_tile.dart` — el + abre la hoja.
- `features/nutrition/presentation/screens/all_foods_screen.dart` — `foods` opcional, `mealType` opcional.
- `features/progress/data/progress_repository.dart` — `date`, `week`, `addWeight`.
- `features/progress/data/week_stats.dart` — `WeekStats`, `DayCalories`.
- `features/progress/presentation/widgets/week_calories_card.dart`, `weekly_summary_grid.dart`, `weight_sparkline.dart`, `register_weight_sheet.dart`.
- `features/progress/presentation/screens/progress_screen.dart` — integra lo anterior y escucha `MealLogState`.
- `features/premium/presentation/screens/premium_screen.dart` — pantalla visual.
- `features/premium/presentation/widgets/premium_promo_card.dart` — tarjeta para Progreso.
- `features/profile/presentation/screens/profile_screen.dart` — fila "NutriLife Premium".

---

### Task 1: Migración SQL de comidas

**Files:**
- Create: `backend/src/database/backups/update_12_10_2026_meals.sql`

**Interfaces:**
- Produces: columna `meal_record_details.meal_type VARCHAR(10) NOT NULL DEFAULT 'SNACK'` con CHECK; índice único `uq_meal_records_user_date (user_id, record_date)`.

- [ ] **Step 1: Escribir el script**

```sql
-- Tipo de comida por línea y un solo registro de comidas por usuario y día.
-- La fusión de duplicados va antes del índice único: si existieran dos
-- registros del mismo día, sus detalles pasan al más antiguo.

BEGIN;

ALTER TABLE meal_record_details
    ADD COLUMN IF NOT EXISTS meal_type VARCHAR(10) NOT NULL DEFAULT 'SNACK';

ALTER TABLE meal_record_details
    DROP CONSTRAINT IF EXISTS chk_meal_record_details_meal_type;
ALTER TABLE meal_record_details
    ADD CONSTRAINT chk_meal_record_details_meal_type
    CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'));

WITH ranked AS (
    SELECT meal_record_id,
           MIN(meal_record_id) OVER (PARTITION BY user_id, record_date) AS keep_id
    FROM meal_records
)
UPDATE meal_record_details d
SET meal_record_id = r.keep_id
FROM ranked r
WHERE d.meal_record_id = r.meal_record_id
  AND r.meal_record_id <> r.keep_id;

DELETE FROM meal_records mr
USING (
    SELECT meal_record_id,
           MIN(meal_record_id) OVER (PARTITION BY user_id, record_date) AS keep_id
    FROM meal_records
) r
WHERE mr.meal_record_id = r.meal_record_id
  AND r.meal_record_id <> r.keep_id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_meal_records_user_date
    ON meal_records (user_id, record_date);

COMMIT;
```

- [ ] **Step 2: Pedir autorización al usuario y aplicarlo**

La base es remota (`backend/.env`). Pedir OK explícito antes de correr. Con OK, desde `backend/`:

```bash
node -e "import('./src/database/connection.js').then(async ({default: pool}) => { const fs = await import('node:fs'); await pool.query(fs.readFileSync('./src/database/backups/update_12_10_2026_meals.sql','utf8')); const r = await pool.query(\"SELECT column_name, column_default FROM information_schema.columns WHERE table_name='meal_record_details' AND column_name='meal_type'\"); const i = await pool.query(\"SELECT indexname FROM pg_indexes WHERE indexname='uq_meal_records_user_date'\"); console.log(r.rows, i.rows); await pool.end(); })"
```

Expected: una fila para `meal_type` con default `'SNACK'::character varying` y una para el índice.

- [ ] **Step 3: Commit**

```bash
git add backend/src/database/backups/update_12_10_2026_meals.sql
git commit -m "feat(db): tipo de comida por línea y un registro por día"
```

---

### Task 2: Backend de comidas (tipo, dueño, día, borrar)

**Files:**
- Create: `backend/src/utils/date.js`
- Modify: `backend/src/modules/meal/meal.repository.js`, `meal.service.js`, `meal.controller.js`, `meal.routes.js`

**Interfaces:**
- Consumes: columna `meal_type` (Task 1).
- Produces:
  - `resolveDateParam(value: string|undefined): string` (en `utils/date.js`).
  - `POST /api/v1/meals/:id/items` body `[{ food_id, quantity, meal_type }]`.
  - `GET /api/v1/meals/day?date=YYYY-MM-DD` → `{ date, totalCalories, meals: { BREAKFAST|LUNCH|DINNER|SNACK: { totalCalories, items: [{ detailId, foodId, name, baseUnit, quantity, calories }] } } }`.
  - `DELETE /api/v1/meals/items/:detailId` → ítem borrado `{ detailId, foodId, quantity, mealType }`.

- [ ] **Step 1: Helper de fecha**

`backend/src/utils/date.js`:

```js
import { AppError } from './AppError.js';

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Fecha YYYY-MM-DD que manda la app (su día local). Sin ella se usa el día
 * UTC del servidor, que es lo que se hacía antes.
 */
export const resolveDateParam = (value) => {
  if (value === undefined || value === null || value === '') {
    return new Date().toISOString().split('T')[0];
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  if (!DATE_PATTERN.test(value) || Number.isNaN(parsed.getTime())
      || parsed.toISOString().slice(0, 10) !== value) {
    throw new AppError('La fecha debe tener el formato YYYY-MM-DD', 400, 'INVALID_DATE');
  }
  return value;
};

/** Suma días a una fecha YYYY-MM-DD. */
export const addDays = (date, days) => {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
};
```

- [ ] **Step 2: Repositorio**

En `meal.repository.js`, reemplazar el `INSERT` de `addItemsToMealRepository` por:

```js
      const { food_id, recipe_id, quantity, meal_type } = item;
      const query = `
        INSERT INTO meal_record_details (meal_record_id, food_id, recipe_id, quantity, meal_type)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
          meal_record_detail_id AS "detailId",
          food_id AS "foodId",
          recipe_id AS "recipeId",
          quantity,
          meal_type AS "mealType"
      `;
      const { rows } = await client.query(query, [mealRecordId, food_id || null, recipe_id || null, quantity, meal_type]);
```

Y agregar al final del archivo:

```js
export const findMealRecordOwnerRepository = async (mealRecordId) => {
  const { rows } = await pool.query(
    'SELECT user_id AS "userId" FROM meal_records WHERE meal_record_id = $1',
    [mealRecordId]
  );
  return rows[0]?.userId ?? null;
};

// Solo líneas de alimentos: las de receta las crea un flujo que la app no usa.
export const getDayMealsRepository = async (userId, date) => {
  const query = `
    SELECT
      mrd.meal_record_detail_id AS "detailId",
      mrd.food_id AS "foodId",
      f.name,
      f.base_unit AS "baseUnit",
      mrd.quantity::float AS quantity,
      mrd.meal_type AS "mealType",
      ROUND(mrd.quantity * f.calories_per_unit)::int AS calories
    FROM meal_records mr
    JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
    JOIN foods f ON f.food_id = mrd.food_id
    WHERE mr.user_id = $1 AND mr.record_date = $2
    ORDER BY mrd.meal_record_detail_id
  `;
  const { rows } = await pool.query(query, [userId, date]);
  return rows;
};

export const deleteMealItemRepository = async (userId, detailId) => {
  const query = `
    DELETE FROM meal_record_details mrd
    USING meal_records mr
    WHERE mrd.meal_record_detail_id = $1
      AND mr.meal_record_id = mrd.meal_record_id
      AND mr.user_id = $2
    RETURNING
      mrd.meal_record_detail_id AS "detailId",
      mrd.food_id AS "foodId",
      mrd.quantity::float AS quantity,
      mrd.meal_type AS "mealType"
  `;
  const { rows } = await pool.query(query, [detailId, userId]);
  return rows[0] ?? null;
};
```

- [ ] **Step 3: Servicio**

En `meal.service.js`:
- Importar `findMealRecordOwnerRepository, getDayMealsRepository, deleteMealItemRepository` y `resolveDateParam` de `../../utils/date.js`.
- En `createMealService`, reemplazar `const mealDate = date || new Date().toISOString().split('T')[0];` por `const mealDate = resolveDateParam(date);` y cambiar el `catch` a `if (error instanceof AppError) throw error; throw new AppError(...)`.
- En `addItemsToMealService`, justo después del chequeo de lista vacía:

```js
    const ownerId = await findMealRecordOwnerRepository(mealRecordId);
    if (ownerId === null || ownerId !== userId) {
      throw new AppError('Registro de comida no encontrado', 404, 'MEAL_RECORD_NOT_FOUND');
    }
```

- Dentro del `for (const item of items)`, al inicio:

```js
      item.meal_type = item.meal_type ?? 'SNACK';
      if (!MEAL_TYPES.includes(item.meal_type)) {
        throw new AppError(`meal_type debe ser uno de: ${MEAL_TYPES.join(', ')}`, 400, 'INVALID_MEAL_TYPE');
      }
```

con `const MEAL_TYPES = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];` arriba del archivo. Nota: `req.user.userId` y `user_id` de la base son enteros; `mealRecordId` llega como string del path, pero se compara el dueño, no el id.

- Agregar:

```js
export const getDayMealsService = async (userId, date) => {
  try {
    const day = resolveDateParam(date);
    const rows = await getDayMealsRepository(userId, day);
    const meals = Object.fromEntries(
      MEAL_TYPES.map((type) => [type, { totalCalories: 0, items: [] }])
    );
    for (const row of rows) {
      const { mealType, ...item } = row;
      const group = meals[mealType] ?? meals.SNACK;
      group.items.push(item);
      group.totalCalories += item.calories;
    }
    const totalCalories = Object.values(meals).reduce((sum, m) => sum + m.totalCalories, 0);
    return { date: day, totalCalories, meals };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};

export const deleteMealItemService = async (userId, detailId) => {
  try {
    const id = Number(detailId);
    if (!Number.isInteger(id) || id <= 0) {
      throw new AppError('detailId debe ser un entero positivo', 400, 'VALIDATION_ERROR');
    }
    const deleted = await deleteMealItemRepository(userId, id);
    if (!deleted) {
      throw new AppError('Ítem no encontrado', 404, 'MEAL_ITEM_NOT_FOUND');
    }
    return deleted;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};
```

- [ ] **Step 4: Controlador y rutas**

`meal.controller.js` (agregar e importar los servicios nuevos):

```js
export const getDayMeals = async (req, res, next) => {
  try {
    const result = await getDayMealsService(req.user.userId, req.query.date);
    return successResponse(res, result, 'Comidas del día obtenidas con éxito');
  } catch (error) {
    next(error);
  }
};

export const deleteMealItem = async (req, res, next) => {
  try {
    const deleted = await deleteMealItemService(req.user.userId, req.params.detailId);
    return successResponse(res, deleted, 'Ítem eliminado con éxito');
  } catch (error) {
    next(error);
  }
};
```

`meal.routes.js` — **antes** de `router.post('/:id/items', ...)`, con su bloque `@openapi` como el resto del archivo:

```js
router.get('/day', authenticateToken(['USER', 'ADMIN']), getDayMeals);

router.delete('/items/:detailId', authenticateToken(['USER', 'ADMIN']), deleteMealItem);
```

- [ ] **Step 5: Verificar que carga y que el SQL es válido**

Desde `backend/`:

```bash
node -e "import('./src/modules/meal/meal.routes.js').then(()=>console.log('routes ok'))"
```

Expected: `routes ok`. Luego validar las 3 consultas nuevas/cambiadas con `EXPLAIN` dentro de `BEGIN READ ONLY` … `ROLLBACK` (script temporal que importa `./src/database/connection.js`, borrarlo después). Expected: las tres `OK`.

- [ ] **Step 6: Commit y push** (solo si Task 1 ya está aplicada en la base)

```bash
git add backend/src/utils/date.js backend/src/modules/meal
git commit -m "feat(meals): tipo de comida, comidas del día y borrar ítems

- POST /meals/:id/items acepta meal_type y verifica que el registro sea del usuario.
- GET /meals/day agrupa las comidas del día por tipo con sus kcal.
- DELETE /meals/items/:detailId borra un ítem propio.
- POST /meals usa la fecha local que manda la app."
git push origin main
```

---

### Task 3: Backend de estadísticas (fecha local y semana)

**Files:**
- Modify: `backend/src/modules/stats/stats.repository.js`, `stats.service.js`, `stats.controller.js`, `stats.routes.js`

**Interfaces:**
- Consumes: `resolveDateParam`, `addDays` (Task 2).
- Produces:
  - `GET /api/v1/stats/today-calories?date=` y `GET /api/v1/stats/consumption-validation?date=`.
  - `GET /api/v1/stats/week?end=YYYY-MM-DD` → `{ start, end, dailyLimit: number|null, days: [{ date, totalConsumed }] (7, ascendente), average, daysOnTarget }`.

- [ ] **Step 1: Repositorio**

Renombrar `getTodayConsumptionCalories(userId)` a `getConsumptionCaloriesByDate(userId, date)`: borrar la línea `const today = ...` y usar `date` en `pool.query(query, [userId, date])`.

Agregar:

```js
export const getWeekConsumptionRepository = async (userId, start, end) => {
  const query = `
    WITH days AS (
      SELECT generate_series($2::date, $3::date, '1 day')::date AS day
    ),
    food_cal AS (
      SELECT mr.record_date AS day, SUM(mrd.quantity * f.calories_per_unit) AS calories
      FROM meal_records mr
      JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
      JOIN foods f ON f.food_id = mrd.food_id
      WHERE mr.user_id = $1 AND mr.record_date BETWEEN $2 AND $3
      GROUP BY mr.record_date
    ),
    recipe_cal AS (
      SELECT mr.record_date AS day,
             SUM(mrd.quantity * (
               SELECT COALESCE(SUM(ri.quantity * f.calories_per_unit), 0)
               FROM recipe_ingredients ri
               JOIN foods f ON ri.food_id = f.food_id
               WHERE ri.recipe_id = mrd.recipe_id
             )) AS calories
      FROM meal_records mr
      JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
      WHERE mr.user_id = $1 AND mr.record_date BETWEEN $2 AND $3
        AND mrd.recipe_id IS NOT NULL
      GROUP BY mr.record_date
    )
    SELECT to_char(d.day, 'YYYY-MM-DD') AS date,
           (COALESCE(fc.calories, 0) + COALESCE(rc.calories, 0))::float AS total
    FROM days d
    LEFT JOIN food_cal fc ON fc.day = d.day
    LEFT JOIN recipe_cal rc ON rc.day = d.day
    ORDER BY d.day
  `;
  const { rows } = await pool.query(query, [userId, start, end]);
  return rows.map((r) => ({ date: r.date, totalConsumed: Math.round(r.total) }));
};
```

- [ ] **Step 2: Servicio**

Extraer el cálculo de la meta de `validateConsumptionService` a una función exportada (mismo código, sin cambiar la fórmula):

```js
/** Meta diaria en kcal, o null si faltan edad, altura o peso. */
export const calculateDailyLimit = ({ age, goal, height, weight }) => {
  if (!age || !height || !weight) return null;
  const parsedHeight = parseFloat(height);
  const heightInCentimeters = parsedHeight <= 3 ? parsedHeight * 100 : parsedHeight;
  const bmr = (10 * parseFloat(weight)) + (6.25 * heightInCentimeters) - (5 * parseInt(age)) - 80;
  const maintenanceCalories = bmr * ACTIVITY_FACTOR;

  let dailyLimit = maintenanceCalories;
  const normalizedGoal = goal?.toLowerCase() || '';

  if (normalizedGoal.includes('perder') || normalizedGoal.includes('bajar') || normalizedGoal.includes('lose')) {
    const deficit = Math.min(MAX_WEIGHT_LOSS_DEFICIT, maintenanceCalories * WEIGHT_LOSS_DEFICIT_RATIO);
    dailyLimit = Math.max(MIN_WEIGHT_LOSS_CALORIES, maintenanceCalories - deficit);
  } else if (normalizedGoal.includes('ganar') || normalizedGoal.includes('subir') || normalizedGoal.includes('gain')) {
    dailyLimit += Math.min(MAX_WEIGHT_LOSS_DEFICIT, maintenanceCalories * 0.15);
  }

  return Math.round(Math.max(MIN_SAFE_DAILY_CALORIES, dailyLimit));
};
```

Cambiar firmas a `validateConsumptionService(userId, date)` y `getTodayCaloriesService(userId, date)`; dentro, `const day = resolveDateParam(date);`, usar `getConsumptionCaloriesByDate(userId, day)`, y en `getTodayCaloriesService` devolver `date: day`. En `validateConsumptionService`, después del chequeo `MISSING_PHYSICAL_DATA` (que se mantiene), usar `const dailyLimit = calculateDailyLimit(userData);` y quitar el cálculo inline. Ojo: el código anterior hacía `Math.round(dailyLimit)` en el return; `calculateDailyLimit` ya devuelve redondeado, y `remaining`/`status` se calculan igual.

Agregar:

```js
export const getWeekStatsService = async (userId, end) => {
  try {
    const endDay = resolveDateParam(end);
    const startDay = addDays(endDay, -6);
    const [userData, days] = await Promise.all([
      getUserNutritionalData(userId),
      getWeekConsumptionRepository(userId, startDay, endDay),
    ]);
    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }
    const dailyLimit = calculateDailyLimit(userData);
    const total = days.reduce((sum, d) => sum + d.totalConsumed, 0);
    const daysOnTarget = dailyLimit === null
      ? 0
      : days.filter((d) => d.totalConsumed > 0 && d.totalConsumed <= dailyLimit).length;
    return {
      start: startDay,
      end: endDay,
      dailyLimit,
      days,
      average: Math.round(total / days.length),
      daysOnTarget,
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};
```

Imports: `getConsumptionCaloriesByDate, getWeekConsumptionRepository` y `resolveDateParam, addDays` de `../../utils/date.js`.

- [ ] **Step 3: Controlador y rutas**

Pasar `req.query.date` a los dos servicios existentes y agregar:

```js
export const getWeekStats = async (req, res, next) => {
  try {
    const stats = await getWeekStatsService(req.user.userId, req.query.end);
    return successResponse(res, stats, 'Resumen semanal consultado con éxito');
  } catch (error) {
    next(error);
  }
};
```

`stats.routes.js` (con su bloque `@openapi`):

```js
router.get('/week',
  authenticateToken(['USER', 'ADMIN']),
  getWeekStats
);
```

- [ ] **Step 4: Verificar**

```bash
node -e "import('./src/modules/stats/stats.routes.js').then(()=>console.log('routes ok'))"
```

Expected: `routes ok`. Validar `getWeekConsumptionRepository` con `EXPLAIN` en `BEGIN READ ONLY` (OK) y además ejecutarla en solo lectura con un `userId` cualquiera y un rango de 7 días: debe devolver 7 filas.

- [ ] **Step 5: Commit y push**

```bash
git add backend/src/modules/stats
git commit -m "feat(stats): resumen semanal y fecha local en las calorías del día"
git push origin main
```

---

### Task 4: App — dominio y datos de comidas

**Files:**
- Create: `nutrilife/lib/core/utils/local_date.dart`, `nutrilife/lib/core/state/meal_log_state.dart`, `nutrilife/lib/features/meals/domain/meal_type.dart`, `nutrilife/lib/features/meals/domain/portions.dart`, `nutrilife/lib/features/meals/data/models/day_meals.dart`, `nutrilife/lib/features/meals/data/meal_repository.dart`
- Modify: `nutrilife/lib/core/network/api_routes.dart`
- Test: `nutrilife/test/features/meals/meal_domain_test.dart`, `nutrilife/test/features/meals/meal_repository_test.dart`

**Interfaces:**
- Consumes: rutas de Task 2.
- Produces:
  - `String localDateString([DateTime? now])` → `'2026-10-12'`.
  - `class MealLogState extends ChangeNotifier { static final MealLogState instance; int get revision; void bump(); }`
  - `enum MealType { breakfast, lunch, dinner, snack }` con `String apiValue`, `String label`, `String emoji`; `static MealType fromApi(String? value)`; `static MealType forTime(DateTime time)`.
  - `String portionsLabel(double portions)`, `String quantityLabel(double portions, String baseUnit)`, `int caloriesFor(double portions, double caloriesPerUnit)`, constantes `kMinPortions = 0.5`, `kMaxPortions = 10.0`, `kPortionStep = 0.5`.
  - `class MealItem { int detailId; int foodId; String name; String baseUnit; double quantity; int calories; }`, `class MealGroup { MealType type; int totalCalories; List<MealItem> items; bool get isEmpty; String get summary; }`, `class DayMeals { String date; int totalCalories; MealGroup of(MealType type); factory DayMeals.fromJson(Map); factory DayMeals.empty(String date); }`
  - `class MealRepository { MealRepository({Dio? dio}); Future<int> addFood({required int foodId, required double portions, required MealType type, DateTime? now}); Future<void> deleteItem(int detailId); Future<DayMeals> getDay(String date); }` — `addFood` devuelve el `detailId` creado. Todos lanzan `Exception(mensaje)` con el `message` del backend.

- [ ] **Step 1: Tests de dominio (fallan)**

`nutrilife/test/features/meals/meal_domain_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/utils/local_date.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/domain/portions.dart';

void main() {
  test('localDateString usa la fecha local con ceros', () {
    expect(localDateString(DateTime(2026, 3, 7, 23, 50)), '2026-03-07');
  });

  group('MealType.forTime', () {
    test('antes de las 11 es desayuno', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 10, 59)), MealType.breakfast);
    });
    test('de 11 a 15:59 es almuerzo', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 11)), MealType.lunch);
      expect(MealType.forTime(DateTime(2026, 1, 1, 15, 59)), MealType.lunch);
    });
    test('desde las 16 es cena', () {
      expect(MealType.forTime(DateTime(2026, 1, 1, 16)), MealType.dinner);
    });
  });

  test('MealType.fromApi cae en snack si no lo conoce', () {
    expect(MealType.fromApi('LUNCH'), MealType.lunch);
    expect(MealType.fromApi('???'), MealType.snack);
    expect(MealType.fromApi(null), MealType.snack);
  });

  group('porciones', () {
    test('etiqueta con medios', () {
      expect(portionsLabel(0.5), '½');
      expect(portionsLabel(1), '1');
      expect(portionsLabel(1.5), '1½');
    });
    test('cantidad en gramos cuando la unidad es numérica', () {
      expect(quantityLabel(1.5, '100 G'), '150 g');
      expect(quantityLabel(2, '250 ML'), '500 ml');
    });
    test('cantidad en la unidad cuando no es numérica', () {
      expect(quantityLabel(1.5, '1 UNIDAD'), '1½ unidad');
      expect(quantityLabel(1, 'TAZA'), '1 taza');
    });
    test('kcal redondeadas', () {
      expect(caloriesFor(1.5, 96), 144);
    });
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/meals/meal_domain_test.dart`
Expected: FAIL (no existen los archivos).

- [ ] **Step 3: Implementar dominio**

`lib/core/utils/local_date.dart`:

```dart
/// Fecha local del dispositivo como YYYY-MM-DD. El backend la usa para que
/// lo que se come de noche no caiga en el día siguiente (UTC).
String localDateString([DateTime? now]) {
  final d = now ?? DateTime.now();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}
```

`lib/core/state/meal_log_state.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Avisa que cambió lo registrado (comidas o peso). Inicio y Progreso lo
/// escuchan para recargar sin que el usuario tenga que tirar para refrescar.
class MealLogState extends ChangeNotifier {
  MealLogState._();

  static final MealLogState instance = MealLogState._();

  int _revision = 0;
  int get revision => _revision;

  void bump() {
    _revision++;
    notifyListeners();
  }
}
```

`lib/features/meals/domain/meal_type.dart`:

```dart
enum MealType {
  breakfast('BREAKFAST', 'Desayuno', '🥑'),
  lunch('LUNCH', 'Almuerzo', '🥗'),
  dinner('DINNER', 'Cena', '🍽️'),
  snack('SNACK', 'Snack', '🍎');

  const MealType(this.apiValue, this.label, this.emoji);

  final String apiValue;
  final String label;
  final String emoji;

  static MealType fromApi(String? value) => MealType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => MealType.snack,
      );

  /// Comida que toca según la hora local.
  static MealType forTime(DateTime time) {
    if (time.hour < 11) return MealType.breakfast;
    if (time.hour < 16) return MealType.lunch;
    return MealType.dinner;
  }
}
```

`lib/features/meals/domain/portions.dart`:

```dart
const double kMinPortions = 0.5;
const double kMaxPortions = 10.0;
const double kPortionStep = 0.5;

final _numericUnit = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(g|ml)\s*$', caseSensitive: false);

/// 0.5 → "½", 1 → "1", 1.5 → "1½".
String portionsLabel(double portions) {
  final whole = portions.floor();
  final hasHalf = (portions - whole) >= 0.5;
  if (whole == 0) return hasHalf ? '½' : '0';
  return hasHalf ? '$whole½' : '$whole';
}

/// "150 g" si la unidad base es numérica (100 G), si no "1½ unidad".
String quantityLabel(double portions, String baseUnit) {
  final match = _numericUnit.firstMatch(baseUnit);
  if (match != null) {
    final amount = double.parse(match.group(1)!.replaceAll(',', '.')) * portions;
    final shown = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
    return '$shown ${match.group(2)!.toLowerCase()}';
  }
  final unit = baseUnit.trim().replaceFirst(RegExp(r'^\d+\s*'), '').toLowerCase();
  return '${portionsLabel(portions)} $unit';
}

int caloriesFor(double portions, double caloriesPerUnit) =>
    (portions * caloriesPerUnit).round();
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test test/features/meals/meal_domain_test.dart`
Expected: PASS.

- [ ] **Step 5: Tests de repositorio (fallan)**

`nutrilife/test/features/meals/meal_repository_test.dart` (adaptador falso por ruta, mismo patrón que `test/features/chatbot/chat_history_test.dart`):

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o);
    final data = routes['${o.method} ${o.path}'];
    return ResponseBody.fromString(
      jsonEncode(data == null
          ? {'success': false, 'message': 'Ítem no encontrado'}
          : {'success': true, 'data': data}),
      data == null ? 404 : 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

(MealRepository, _Adapter) _repo(Map<String, Object> routes) {
  final adapter = _Adapter(routes);
  return (
    MealRepository(dio: Dio(BaseOptions(baseUrl: 'https://t.local'))..httpClientAdapter = adapter),
    adapter,
  );
}

void main() {
  test('addFood crea el registro del día local y agrega con meal_type', () async {
    final (repo, adapter) = _repo({
      'POST /meals': {'mealRecordId': 9},
      'POST /meals/9/items': [
        {'detailId': 41, 'foodId': 3, 'quantity': 1.5, 'mealType': 'LUNCH'}
      ],
    });

    final id = await repo.addFood(
      foodId: 3,
      portions: 1.5,
      type: MealType.lunch,
      now: DateTime(2026, 10, 12, 23, 30),
    );

    expect(id, 41);
    expect(adapter.requests[0].data, {'date': '2026-10-12'});
    expect(adapter.requests[1].data, [
      {'food_id': 3, 'quantity': 1.5, 'meal_type': 'LUNCH'}
    ]);
  });

  test('getDay arma los grupos y el resumen', () async {
    final (repo, adapter) = _repo({
      'GET /meals/day': {
        'date': '2026-10-12',
        'totalCalories': 240,
        'meals': {
          'BREAKFAST': {'totalCalories': 0, 'items': []},
          'LUNCH': {
            'totalCalories': 240,
            'items': [
              {'detailId': 1, 'foodId': 3, 'name': 'Tilapia', 'baseUnit': '100 G', 'quantity': 1.5, 'calories': 144},
              {'detailId': 2, 'foodId': 5, 'name': 'Arroz', 'baseUnit': '100 G', 'quantity': 1, 'calories': 96},
            ]
          },
          'DINNER': {'totalCalories': 0, 'items': []},
          'SNACK': {'totalCalories': 0, 'items': []},
        }
      },
    });

    final day = await repo.getDay('2026-10-12');

    expect(adapter.requests.single.queryParameters, {'date': '2026-10-12'});
    expect(day.totalCalories, 240);
    expect(day.of(MealType.lunch).summary, 'Tilapia, Arroz • 240 kcal');
    expect(day.of(MealType.breakfast).isEmpty, isTrue);
  });

  test('deleteItem propaga el mensaje del backend', () async {
    final (repo, _) = _repo({});
    expect(
      repo.deleteItem(7),
      throwsA(isA<Exception>().having((e) => '$e', 'msg', contains('Ítem no encontrado'))),
    );
  });
}
```

- [ ] **Step 6: Correr y ver que falla**

Run: `flutter test test/features/meals/meal_repository_test.dart`
Expected: FAIL (no existe `meal_repository.dart`).

- [ ] **Step 7: Implementar datos**

`lib/core/network/api_routes.dart`, agregar:

```dart
  static const String meals = '/meals';
  static String mealItems(int mealRecordId) => '/meals/$mealRecordId/items';
  static const String mealsDay = '/meals/day';
  static String mealItem(int detailId) => '/meals/items/$detailId';
  static const String statsWeek = '/stats/week';
  static const String userPhysical = '/user/physical';
```

`lib/features/meals/data/models/day_meals.dart`:

```dart
import '../../domain/meal_type.dart';

class MealItem {
  final int detailId;
  final int foodId;
  final String name;
  final String baseUnit;
  final double quantity;
  final int calories;

  const MealItem({
    required this.detailId,
    required this.foodId,
    required this.name,
    required this.baseUnit,
    required this.quantity,
    required this.calories,
  });

  factory MealItem.fromJson(Map map) => MealItem(
        detailId: (map['detailId'] as num).toInt(),
        foodId: (map['foodId'] as num).toInt(),
        name: map['name'] as String? ?? '',
        baseUnit: map['baseUnit'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        calories: (map['calories'] as num?)?.round() ?? 0,
      );
}

class MealGroup {
  final MealType type;
  final int totalCalories;
  final List<MealItem> items;

  const MealGroup({required this.type, required this.totalCalories, required this.items});

  bool get isEmpty => items.isEmpty;

  /// "Tilapia, Arroz • 240 kcal" o "Aún no registrada".
  String get summary => isEmpty
      ? 'Aún no registrada'
      : '${items.map((i) => i.name).join(', ')} • $totalCalories kcal';

  factory MealGroup.fromJson(MealType type, Map? map) => MealGroup(
        type: type,
        totalCalories: (map?['totalCalories'] as num?)?.round() ?? 0,
        items: (map?['items'] as List? ?? const [])
            .whereType<Map>()
            .map(MealItem.fromJson)
            .toList(),
      );
}

class DayMeals {
  final String date;
  final int totalCalories;
  final Map<MealType, MealGroup> _groups;

  DayMeals({required this.date, required this.totalCalories, required Map<MealType, MealGroup> groups})
      : _groups = groups;

  MealGroup of(MealType type) =>
      _groups[type] ?? MealGroup(type: type, totalCalories: 0, items: const []);

  factory DayMeals.fromJson(Map map) {
    final meals = map['meals'] as Map? ?? const {};
    return DayMeals(
      date: map['date'] as String? ?? '',
      totalCalories: (map['totalCalories'] as num?)?.round() ?? 0,
      groups: {
        for (final type in MealType.values)
          type: MealGroup.fromJson(type, meals[type.apiValue] as Map?),
      },
    );
  }

  factory DayMeals.empty(String date) =>
      DayMeals(date: date, totalCalories: 0, groups: const {});
}
```

`lib/features/meals/data/meal_repository.dart`:

```dart
import 'package:dio/dio.dart';
import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/local_date.dart';
import '../domain/meal_type.dart';
import 'models/day_meals.dart';

class MealRepository {
  final Dio _dio;

  MealRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Registra [portions] porciones del alimento en la comida [type] del día
  /// local. Devuelve el id del ítem (para "Deshacer").
  Future<int> addFood({
    required int foodId,
    required double portions,
    required MealType type,
    DateTime? now,
  }) async {
    try {
      final record = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.meals,
        data: {'date': localDateString(now)},
      );
      final recordId = (record.data?['data']?['mealRecordId'] as num).toInt();
      final items = await _dio.post<Map<String, dynamic>>(
        ApiRoutes.mealItems(recordId),
        data: [
          {'food_id': foodId, 'quantity': portions, 'meal_type': type.apiValue}
        ],
      );
      final created = (items.data?['data'] as List).first as Map;
      return (created['detailId'] as num).toInt();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudo registrar la comida');
    }
  }

  Future<void> deleteItem(int detailId) async {
    try {
      await _dio.delete<void>(ApiRoutes.mealItem(detailId));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudo borrar');
    }
  }

  Future<DayMeals> getDay(String date) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.mealsDay,
        queryParameters: {'date': date},
      );
      final data = response.data?['data'];
      return data is Map ? DayMeals.fromJson(data) : DayMeals.empty(date);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'No se pudieron cargar tus comidas');
    }
  }
}
```

- [ ] **Step 8: Correr y ver que pasa**

Run: `flutter test test/features/meals/`
Expected: PASS (todos).

- [ ] **Step 9: Commit**

```bash
git add nutrilife/lib/core/utils/local_date.dart nutrilife/lib/core/state/meal_log_state.dart nutrilife/lib/core/network/api_routes.dart nutrilife/lib/features/meals nutrilife/test/features/meals
git commit -m "feat(meals): dominio y repositorio de comidas en la app"
```

---

### Task 5: Hoja "Agregar a tu día" y el + de Alimentos

**Files:**
- Create: `nutrilife/lib/features/meals/presentation/widgets/add_food_sheet.dart`
- Modify: `nutrilife/lib/features/nutrition/presentation/widgets/food_list_tile.dart`
- Test: `nutrilife/test/features/meals/add_food_sheet_test.dart`

**Interfaces:**
- Consumes: `MealType`, `portions.dart`, `MealRepository`, `MealLogState` (Task 4); `FoodModel` (`foodId`, `name`, `caloriesPerUnit`, `baseUnit`).
- Produces:
  - `Future<void> showAddFoodSheet(BuildContext context, FoodModel food, {MealType? initialType, MealRepository? repository, DateTime Function()? clock})` — al guardar cierra la hoja, llama `MealLogState.instance.bump()` y muestra SnackBar "Agregado a {label} · {kcal} kcal" con acción **Deshacer** (borra y vuelve a hacer `bump()`).
  - `class FoodListTile` gana `final MealType? mealType;` y `@visibleForTesting final MealRepository? repository;`; su + llama `showAddFoodSheet(context, food, initialType: mealType, repository: repository)`.

- [ ] **Step 1: Tests (fallan)**

`nutrilife/test/features/meals/add_food_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';
import 'package:nutrilife/features/meals/presentation/widgets/add_food_sheet.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';

class _RepoFalso extends MealRepository {
  final added = <(int, double, MealType)>[];
  final deleted = <int>[];

  @override
  Future<int> addFood({required int foodId, required double portions, required MealType type, DateTime? now}) async {
    added.add((foodId, portions, type));
    return 77;
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

final _tilapia = FoodModel(
  foodId: 3, name: 'Tilapia', caloriesPerUnit: 96, baseUnit: '100 G', isGlobal: true, isActive: true,
);

Future<_RepoFalso> _open(WidgetTester tester, {DateTime? at, MealType? initial}) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showAddFoodSheet(
            context, _tilapia,
            initialType: initial,
            repository: repo,
            clock: () => at ?? DateTime(2026, 10, 12, 13),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('preselecciona la comida según la hora', (tester) async {
    await _open(tester, at: DateTime(2026, 10, 12, 8));
    expect(find.text('Agregar a Desayuno'), findsOneWidget);
  });

  testWidgets('respeta la comida con la que se abrió', (tester) async {
    await _open(tester, initial: MealType.snack);
    expect(find.text('Agregar a Snack'), findsOneWidget);
  });

  testWidgets('las porciones cambian de media en media con su cálculo', (tester) async {
    await _open(tester);
    expect(find.text('1 porción · 100 g · 96 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Más'));
    await tester.pump();
    expect(find.text('1½ porciones · 150 g · 144 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Menos'));
    await tester.tap(find.byTooltip('Menos'));
    await tester.pump();
    expect(find.text('½ porción · 50 g · 48 kcal'), findsOneWidget);

    // No baja de media porción.
    await tester.tap(find.byTooltip('Menos'));
    await tester.pump();
    expect(find.text('½ porción · 50 g · 48 kcal'), findsOneWidget);
  });

  testWidgets('guarda con el tipo elegido y avisa', (tester) async {
    final revision = MealLogState.instance.revision;
    final repo = await _open(tester);

    await tester.tap(find.text('Cena'));
    await tester.pump();
    await tester.tap(find.text('Agregar a Cena'));
    await tester.pumpAndSettle();

    expect(repo.added.single, (3, 1.0, MealType.dinner));
    expect(MealLogState.instance.revision, revision + 1);
    expect(find.text('Agregado a Cena · 96 kcal'), findsOneWidget);
  });

  testWidgets('Deshacer borra lo que se acaba de agregar', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text('Agregar a Almuerzo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(repo.deleted.single, 77);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/meals/add_food_sheet_test.dart`
Expected: FAIL (no existe `add_food_sheet.dart`).

- [ ] **Step 3: Implementar la hoja**

`lib/features/meals/presentation/widgets/add_food_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../nutrition/data/models/food_model.dart';
import '../../data/meal_repository.dart';
import '../../domain/meal_type.dart';
import '../../domain/portions.dart';

Future<void> showAddFoodSheet(
  BuildContext context,
  FoodModel food, {
  MealType? initialType,
  MealRepository? repository,
  DateTime Function()? clock,
}) async {
  final now = (clock ?? DateTime.now)();
  final messenger = ScaffoldMessenger.of(context);
  final repo = repository ?? MealRepository();

  final result = await showModalBottomSheet<({int detailId, MealType type, int calories})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _AddFoodSheet(
      food: food,
      initialType: initialType ?? MealType.forTime(now),
      repository: repo,
      now: now,
    ),
  );
  if (result == null) return;

  MealLogState.instance.bump();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Agregado a ${result.type.label} · ${result.calories} kcal'),
      backgroundColor: AppTheme.primaryStart,
      action: SnackBarAction(
        label: 'Deshacer',
        textColor: Colors.white,
        onPressed: () async {
          try {
            await repo.deleteItem(result.detailId);
            MealLogState.instance.bump();
          } catch (_) {
            messenger.showSnackBar(const SnackBar(content: Text('No se pudo deshacer')));
          }
        },
      ),
    ));
}

class _AddFoodSheet extends StatefulWidget {
  final FoodModel food;
  final MealType initialType;
  final MealRepository repository;
  final DateTime now;

  const _AddFoodSheet({
    required this.food,
    required this.initialType,
    required this.repository,
    required this.now,
  });

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  static const _green = Color(0xFF0A6B3F);

  late MealType _type = widget.initialType;
  double _portions = 1;
  bool _saving = false;
  String? _error;

  int get _calories => caloriesFor(_portions, widget.food.caloriesPerUnit);

  String get _detail {
    final unit = _portions <= 1 ? 'porción' : 'porciones';
    return '${portionsLabel(_portions)} $unit · '
        '${quantityLabel(_portions, widget.food.baseUnit)} · $_calories kcal';
  }

  void _step(double delta) {
    setState(() {
      _portions = (_portions + delta).clamp(kMinPortions, kMaxPortions);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await widget.repository.addFood(
        foodId: widget.food.foodId,
        portions: _portions,
        type: _type,
        now: widget.now,
      );
      if (!mounted) return;
      Navigator.of(context).pop((detailId: id, type: _type, calories: _calories));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.food.name,
              style: const TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.food.caloriesPerUnit.round()} kcal por ${widget.food.baseUnit.toLowerCase()}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in MealType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                    selectedColor: const Color(0xFFDCFCE7),
                    labelStyle: TextStyle(
                      color: _type == type ? _green : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _type == type ? _green : const Color(0xFFE2E8F0),
                    ),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Menos',
                  onTap: _portions > kMinPortions ? () => _step(-kPortionStep) : null,
                ),
                Expanded(
                  child: Text(
                    _detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C2F31),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Más',
                  onTap: _portions < kMaxPortions ? () => _step(kPortionStep) : null,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                child: Text('Agregar a ${_type.label}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0A6B3F),
      ),
    );
  }
}
```

Nota: el test de "no baja de media porción" toca "Menos" con el botón deshabilitado (`onPressed: null`); `tester.tap` sobre un botón deshabilitado no hace nada, que es lo esperado.

- [ ] **Step 4: Conectar el + de `FoodListTile`**

En `lib/features/nutrition/presentation/widgets/food_list_tile.dart`:
- Imports: `../../../meals/data/meal_repository.dart`, `../../../meals/domain/meal_type.dart`, `../../../meals/presentation/widgets/add_food_sheet.dart`; quitar el import de `app_theme.dart` si queda sin uso.
- Campos y constructor:

```dart
  final FoodModel food;

  /// Comida en la que se abre la hoja (al venir desde "Comidas de hoy").
  final MealType? mealType;

  @visibleForTesting
  final MealRepository? repository;

  const FoodListTile({super.key, required this.food, this.mealType, this.repository});
```

- Reemplazar el `onTap` del `GestureDetector` del + por:

```dart
            onTap: () => showAddFoodSheet(
              context,
              food,
              initialType: mealType,
              repository: repository,
            ),
```

- [ ] **Step 5: Correr tests**

Run: `flutter test test/features/meals test/features/nutrition`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/meals/presentation/widgets/add_food_sheet.dart nutrilife/lib/features/nutrition/presentation/widgets/food_list_tile.dart nutrilife/test/features/meals/add_food_sheet_test.dart
git commit -m "feat(meals): hoja para registrar un alimento con tipo y porciones"
```

---

### Task 6: "Comidas de hoy" real en Inicio

**Files:**
- Create: `nutrilife/lib/features/meals/presentation/widgets/day_meals_list.dart`, `nutrilife/lib/features/meals/presentation/widgets/meal_detail_sheet.dart`, `nutrilife/lib/features/home/presentation/widgets/today_meals_section.dart`
- Modify: `nutrilife/lib/features/home/presentation/widgets/meal_card.dart`, `nutrilife/lib/features/nutrition/presentation/screens/all_foods_screen.dart`, `nutrilife/lib/features/home/presentation/screens/dashboard_screen.dart:155-198`
- Test: `nutrilife/test/features/home/today_meals_section_test.dart`

**Interfaces:**
- Consumes: Task 4 y Task 5.
- Produces:
  - `MealCard` gana `final VoidCallback? onTap; final VoidCallback? onAdd;` (el + pasa a ser `InkWell` con `tooltip`-equivalente `Semantics(label: 'Agregar a {title}')`).
  - `class DayMealsList extends StatelessWidget { DayMealsList({required DayMeals day, required ValueChanged<MealGroup> onOpen, ValueChanged<MealType>? onAdd}); }` — 4 `MealCard` en orden Desayuno, Almuerzo, Cena, Snack; sin `onAdd` no muestra acción del + (historial de días pasados).
  - `Future<void> showMealDetailSheet(BuildContext context, MealGroup group, {MealRepository? repository})` — lista con 🗑 (tooltip `Borrar {name}`); al borrar llama `deleteItem`, `MealLogState.instance.bump()` y cierra la hoja.
  - `class TodayMealsSection extends StatefulWidget { TodayMealsSection({MealRepository? repository, DateTime Function()? clock, VoidCallback? onOpenHistory}); }` — carga `getDay(localDateString(clock()))`, recarga con `MealLogState`.
  - `AllFoodsScreen({List<FoodModel>? foods, MealType? mealType, FoodRepository? foodRepository})` — si `foods` es null los carga con `FoodRepository().getFoods()`; con `mealType` el título es "Agregar a {label}" y pasa `mealType` a cada `FoodListTile`.

- [ ] **Step 1: Test (falla)**

`nutrilife/test/features/home/today_meals_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/meal_log_state.dart';
import 'package:nutrilife/features/home/presentation/widgets/today_meals_section.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';

class _RepoFalso extends MealRepository {
  int loads = 0;
  final deleted = <int>[];
  String? lastDate;

  @override
  Future<DayMeals> getDay(String date) async {
    loads++;
    lastDate = date;
    return DayMeals.fromJson({
      'date': date,
      'totalCalories': 144,
      'meals': {
        'LUNCH': {
          'totalCalories': 144,
          'items': [
            {'detailId': 5, 'foodId': 3, 'name': 'Tilapia', 'baseUnit': '100 G', 'quantity': 1.5, 'calories': 144}
          ]
        },
      },
    });
  }

  @override
  Future<void> deleteItem(int detailId) async => deleted.add(detailId);
}

Future<_RepoFalso> _pump(WidgetTester tester) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TodayMealsSection(repository: repo, clock: () => DateTime(2026, 10, 12, 21)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('muestra lo registrado hoy y lo que falta', (tester) async {
    final repo = await _pump(tester);

    expect(repo.lastDate, '2026-10-12');
    expect(find.text('Tilapia • 144 kcal'), findsOneWidget);
    expect(find.text('Aún no registrada'), findsNWidgets(3));
    expect(find.text('Snack'), findsOneWidget);
  });

  testWidgets('recarga cuando se registra algo en otra pantalla', (tester) async {
    final repo = await _pump(tester);
    MealLogState.instance.bump();
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
  });

  testWidgets('tocar una comida muestra el detalle y permite borrar', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();
    expect(find.text('1½ porciones · 150 g'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar Tilapia'));
    await tester.pumpAndSettle();
    expect(repo.deleted.single, 5);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/home/today_meals_section_test.dart`
Expected: FAIL (no existe `today_meals_section.dart`).

- [ ] **Step 3: `MealCard` con callbacks**

En `meal_card.dart`, agregar `final VoidCallback? onTap; final VoidCallback? onAdd;` (opcionales en el constructor). Envolver el `Container` raíz en:

```dart
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: <Container actual>,
      ),
    );
```

y reemplazar el `Container` del + (40×40) por:

```dart
          if (onAdd != null)
            Semantics(
              label: 'Agregar a $title',
              button: true,
              child: InkWell(
                onTap: onAdd,
                customBorder: const CircleBorder(),
                child: <Container 40×40 actual con el Icon add>,
              ),
            ),
```

- [ ] **Step 4: `DayMealsList` y detalle**

`lib/features/meals/presentation/widgets/day_meals_list.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/meal_card.dart';
import '../../data/models/day_meals.dart';
import '../../domain/meal_type.dart';

/// Las cuatro comidas de un día como tarjetas.
class DayMealsList extends StatelessWidget {
  final DayMeals day;
  final ValueChanged<MealGroup> onOpen;
  final ValueChanged<MealType>? onAdd;

  const DayMealsList({super.key, required this.day, required this.onOpen, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final type in MealType.values) ...[
          MealCard(
            emoji: type.emoji,
            title: type.label,
            description: day.of(type).summary,
            isLogged: !day.of(type).isEmpty,
            onTap: day.of(type).isEmpty ? null : () => onOpen(day.of(type)),
            onAdd: onAdd == null ? null : () => onAdd!(type),
          ),
          if (type != MealType.values.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
```

`lib/features/meals/presentation/widgets/meal_detail_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../data/meal_repository.dart';
import '../../data/models/day_meals.dart';
import '../../domain/portions.dart';

Future<void> showMealDetailSheet(
  BuildContext context,
  MealGroup group, {
  MealRepository? repository,
}) {
  final repo = repository ?? MealRepository();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.type.label} · ${group.totalCalories} kcal',
              style: const TextStyle(
                color: Color(0xFF2C2F31),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in group.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${portionsLabel(item.quantity)} ${item.quantity <= 1 ? 'porción' : 'porciones'} · '
                  '${quantityLabel(item.quantity, item.baseUnit)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${item.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      tooltip: 'Borrar ${item.name}',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        try {
                          await repo.deleteItem(item.detailId);
                          MealLogState.instance.bump();
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        } catch (e) {
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 5: `AllFoodsScreen` en modo selección**

En `all_foods_screen.dart`:
- Campos: `final List<FoodModel>? foods; final MealType? mealType; final FoodRepository? foodRepository;` y constructor `const AllFoodsScreen({super.key, this.foods, this.mealType, this.foodRepository});`.
- Estado: `List<FoodModel> _all = const []; List<FoodModel> _visible = const []; bool _loading = false; String? _error;`. En `initState`: si `widget.foods != null` asignar a `_all` y `_visible`; si no, `_load()`:

```dart
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final foods = await (widget.foodRepository ?? FoodRepository()).getFoods();
      if (!mounted) return;
      setState(() {
        _all = foods;
        _visible = FoodsViewModel.filterFoods(foods, _searchController.text);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
```

- El listener del buscador filtra sobre `_all`. Título: `widget.mealType == null ? 'Todos los alimentos' : 'Agregar a ${widget.mealType!.label}'`. Con `_loading` mostrar `CircularProgressIndicator` centrado en el `Expanded`; con `_error` el texto y un `TextButton('Reintentar')` a `_load`. Cada tile: `FoodListTile(food: _visible[index], mealType: widget.mealType)`.
- Los tests de `foods_screen_test.dart` siguen pasando (abren con `foods`).

- [ ] **Step 6: `TodayMealsSection`**

`lib/features/home/presentation/widgets/today_meals_section.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/local_date.dart';
import '../../../meals/data/meal_repository.dart';
import '../../../meals/data/models/day_meals.dart';
import '../../../meals/presentation/widgets/day_meals_list.dart';
import '../../../meals/presentation/widgets/meal_detail_sheet.dart';
import '../../../nutrition/presentation/screens/all_foods_screen.dart';

/// "Comidas de hoy" con lo que el usuario registró de verdad.
class TodayMealsSection extends StatefulWidget {
  final MealRepository? repository;
  final DateTime Function()? clock;
  final VoidCallback? onOpenHistory;

  const TodayMealsSection({super.key, this.repository, this.clock, this.onOpenHistory});

  @override
  State<TodayMealsSection> createState() => _TodayMealsSectionState();
}

class _TodayMealsSectionState extends State<TodayMealsSection> {
  late final MealRepository _repository = widget.repository ?? MealRepository();
  late Future<DayMeals> _future;

  String get _today => localDateString((widget.clock ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _future = _repository.getDay(_today);
    MealLogState.instance.addListener(_reload);
  }

  @override
  void dispose() {
    MealLogState.instance.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _repository.getDay(_today));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comidas de hoy',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton(
              onPressed: widget.onOpenHistory,
              child: const Text(
                'Ver historial',
                style: TextStyle(
                  color: AppTheme.primaryStart,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<DayMeals>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryStart)),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  TextButton(onPressed: _reload, child: const Text('Reintentar')),
                ],
              );
            }
            return DayMealsList(
              day: snapshot.data!,
              onOpen: (group) => showMealDetailSheet(context, group, repository: _repository),
              onAdd: (type) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AllFoodsScreen(mealType: type)),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Usarla en el dashboard**

En `dashboard_screen.dart` `_buildHomeTab`, reemplazar desde `const Row(` del título "Comidas de hoy" hasta la última `MealCard` de Cena (líneas ~155-197) por:

```dart
          TodayMealsSection(
            onOpenHistory: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
            ),
          ),
```

Imports: `../widgets/today_meals_section.dart` y `../../../meals/presentation/screens/meal_history_screen.dart` (se crea en Task 7; hasta entonces dejar `onOpenHistory: null` y conectarlo en Task 7). Quitar el import de `meal_card.dart` si queda sin uso.

- [ ] **Step 8: Correr tests**

Run: `flutter test test/features/home test/features/nutrition test/features/meals`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add nutrilife/lib/features/home nutrilife/lib/features/meals nutrilife/lib/features/nutrition/presentation/screens/all_foods_screen.dart nutrilife/test/features/home
git commit -m "feat(home): Comidas de hoy con lo registrado, detalle y agregar por comida"
```

---

### Task 7: Historial de comidas por día

**Files:**
- Create: `nutrilife/lib/features/meals/presentation/screens/meal_history_screen.dart`
- Modify: `nutrilife/lib/features/home/presentation/screens/dashboard_screen.dart` (conectar `onOpenHistory`)
- Test: `nutrilife/test/features/meals/meal_history_screen_test.dart`

**Interfaces:**
- Consumes: `MealRepository.getDay`, `DayMealsList`, `showMealDetailSheet`, `MealLogState`, `localDateString`.
- Produces: `class MealHistoryScreen extends StatefulWidget { const MealHistoryScreen({super.key, MealRepository? repository, DateTime Function()? clock}); }` — botones con tooltip `Día anterior` / `Día siguiente`; el siguiente se deshabilita en hoy; encabezado "Hoy", "Ayer" o "Lun 5 oct"; total "{n} kcal".

- [ ] **Step 1: Test (falla)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/data/models/day_meals.dart';
import 'package:nutrilife/features/meals/presentation/screens/meal_history_screen.dart';

class _RepoFalso extends MealRepository {
  final dates = <String>[];

  @override
  Future<DayMeals> getDay(String date) async {
    dates.add(date);
    return DayMeals.empty(date);
  }
}

void main() {
  testWidgets('navega por días y no pasa de hoy', (tester) async {
    final repo = _RepoFalso();
    await tester.pumpWidget(MaterialApp(
      home: MealHistoryScreen(repository: repo, clock: () => DateTime(2026, 10, 12, 9)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(repo.dates.last, '2026-10-12');
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Ayer'), findsOneWidget);
    expect(repo.dates.last, '2026-10-11');

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sáb 10 oct'), findsOneWidget);

    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pumpAndSettle();
    expect(repo.dates.last, '2026-10-11');
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/meals/meal_history_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/local_date.dart';
import '../../data/meal_repository.dart';
import '../../data/models/day_meals.dart';
import '../widgets/day_meals_list.dart';
import '../widgets/meal_detail_sheet.dart';

class MealHistoryScreen extends StatefulWidget {
  final MealRepository? repository;
  final DateTime Function()? clock;

  const MealHistoryScreen({super.key, this.repository, this.clock});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  late final MealRepository _repository = widget.repository ?? MealRepository();
  late final DateTime _today = _dateOnly((widget.clock ?? DateTime.now)());
  late DateTime _day = _today;
  late Future<DayMeals> _future = _repository.getDay(localDateString(_day));

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    MealLogState.instance.addListener(_reload);
  }

  @override
  void dispose() {
    MealLogState.instance.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _repository.getDay(localDateString(_day)));
  }

  void _move(int days) {
    _day = DateTime(_day.year, _day.month, _day.day + days);
    _reload();
  }

  String get _title {
    final diff = _today.difference(_day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${_weekdays[_day.weekday - 1]} ${_day.day} ${_months[_day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _day == _today;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
        title: const Text(
          'Historial de comidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Día anterior',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Día siguiente',
                onPressed: isToday ? null : () => _move(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<DayMeals>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryStart)),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                    TextButton(onPressed: _reload, child: const Text('Reintentar')),
                  ],
                );
              }
              final day = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.totalCalories} kcal',
                    style: const TextStyle(
                      color: AppTheme.primaryStart,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DayMealsList(
                    day: day,
                    onOpen: (group) => showMealDetailSheet(context, group, repository: _repository),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Conectar "Ver historial"** en el dashboard como en Task 6 Step 7.

- [ ] **Step 5: Correr tests**

Run: `flutter test test/features/meals test/features/home`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/meals/presentation/screens nutrilife/lib/features/home/presentation/screens/dashboard_screen.dart nutrilife/test/features/meals/meal_history_screen_test.dart
git commit -m "feat(meals): historial de comidas por día"
```

---

### Task 8: Progreso — fecha local, semana y resumen semanal

**Files:**
- Create: `nutrilife/lib/features/progress/data/week_stats.dart`, `nutrilife/lib/features/progress/presentation/widgets/week_calories_card.dart`, `nutrilife/lib/features/progress/presentation/widgets/weekly_summary_grid.dart`
- Modify: `nutrilife/lib/features/progress/data/progress_repository.dart`, `nutrilife/lib/features/progress/presentation/screens/progress_screen.dart`
- Test: `nutrilife/test/features/progress/week_stats_test.dart`, `nutrilife/test/features/progress/week_calories_card_test.dart`

**Interfaces:**
- Consumes: `/stats/week`, `localDateString`, `MealLogState`.
- Produces:
  - `class DayCalories { DateTime date; int totalConsumed; }`, `class WeekStats { int? dailyLimit; List<DayCalories> days; int average; int daysOnTarget; factory WeekStats.fromJson(Map); }`.
  - `ProgressData` gana `final WeekStats? week;` (constructor con `this.week`).
  - `ProgressRepository.fetchProgress({DateTime? now})` manda `queryParameters: {'date': localDateString(now)}` a las dos rutas de stats y `{'end': ...}` a `/stats/week` (opcional como las otras).
  - `ProgressScreen` gana `@visibleForTesting final ProgressRepository? repository;` y escucha `MealLogState`.
  - `class WeekCaloriesCard extends StatefulWidget { WeekCaloriesCard({required WeekStats week, DateTime Function()? clock, VoidCallback? onCompleteProfile}); }`.
  - `class WeeklySummaryGrid extends StatelessWidget { WeeklySummaryGrid({required WeekStats week}); }`.

- [ ] **Step 1: Tests (fallan)**

`nutrilife/test/features/progress/week_stats_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/week_stats.dart';

void main() {
  test('lee los 7 días, la meta y los promedios', () {
    final week = WeekStats.fromJson({
      'dailyLimit': 2120,
      'average': 1850,
      'daysOnTarget': 4,
      'days': [
        for (var i = 6; i <= 12; i++) {'date': '2026-10-${i.toString().padLeft(2, '0')}', 'totalConsumed': i * 100},
      ],
    });

    expect(week.days, hasLength(7));
    expect(week.days.first.date, DateTime(2026, 10, 6));
    expect(week.days.last.totalConsumed, 1200);
    expect(week.dailyLimit, 2120);
    expect(week.total, 6300);
  });

  test('sin meta deja dailyLimit en null', () {
    final week = WeekStats.fromJson({'dailyLimit': null, 'average': 0, 'daysOnTarget': 0, 'days': []});
    expect(week.dailyLimit, isNull);
  });
}
```

`nutrilife/test/features/progress/week_calories_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/week_stats.dart';
import 'package:nutrilife/features/progress/presentation/widgets/week_calories_card.dart';

WeekStats _week({int? limit = 2000}) => WeekStats.fromJson({
      'dailyLimit': limit,
      'average': 1850,
      'daysOnTarget': 4,
      'days': [
        // 2026-10-06 es martes.
        for (var i = 6; i <= 12; i++) {'date': '2026-10-${i.toString().padLeft(2, '0')}', 'totalConsumed': 1500 + i * 50},
      ],
    });

Future<void> _pump(WidgetTester tester, WeekStats week) => tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WeekCaloriesCard(week: week, clock: () => DateTime(2026, 10, 12, 9))),
    ));

void main() {
  testWidgets('iniciales de los días reales y resumen', (tester) async {
    await _pump(tester, _week());

    // Mar Mié Jue Vie Sáb Dom Lun
    for (final initial in ['M', 'J', 'V', 'S', 'D', 'L']) {
      expect(find.text(initial), findsWidgets);
    }
    expect(find.text('Promedio: 1.850 kcal/día · 4 de 7 días en tu meta'), findsOneWidget);
  });

  testWidgets('tocar una barra muestra ese día', (tester) async {
    await _pump(tester, _week());
    await tester.tap(find.byKey(const ValueKey('week-bar-2026-10-08')));
    await tester.pump();
    expect(find.text('Jue 8 · 1.900 kcal'), findsOneWidget);
  });

  testWidgets('sin meta muestra solo el promedio y el enlace', (tester) async {
    await _pump(tester, _week(limit: null));
    expect(find.text('Promedio: 1.850 kcal/día'), findsOneWidget);
    expect(find.text('Completa tu perfil'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/progress`
Expected: FAIL.

- [ ] **Step 3: `WeekStats`**

`lib/features/progress/data/week_stats.dart`:

```dart
class DayCalories {
  final DateTime date;
  final int totalConsumed;

  const DayCalories({required this.date, required this.totalConsumed});
}

class WeekStats {
  final int? dailyLimit;
  final List<DayCalories> days;
  final int average;
  final int daysOnTarget;

  const WeekStats({
    required this.dailyLimit,
    required this.days,
    required this.average,
    required this.daysOnTarget,
  });

  int get total => days.fold(0, (sum, d) => sum + d.totalConsumed);

  factory WeekStats.fromJson(Map map) => WeekStats(
        dailyLimit: (map['dailyLimit'] as num?)?.round(),
        average: (map['average'] as num?)?.round() ?? 0,
        daysOnTarget: (map['daysOnTarget'] as num?)?.round() ?? 0,
        days: (map['days'] as List? ?? const [])
            .whereType<Map>()
            .map((d) {
              final parts = (d['date'] as String).split('-').map(int.parse).toList();
              return DayCalories(
                date: DateTime(parts[0], parts[1], parts[2]),
                totalConsumed: (d['totalConsumed'] as num?)?.round() ?? 0,
              );
            })
            .toList(),
      );
}
```

- [ ] **Step 4: `WeekCaloriesCard`**

`lib/features/progress/presentation/widgets/week_calories_card.dart` (formato de miles con punto, como el resto de Progreso):

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';

String formatKcal(int value) => value
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

class WeekCaloriesCard extends StatefulWidget {
  final WeekStats week;
  final DateTime Function()? clock;
  final VoidCallback? onCompleteProfile;

  const WeekCaloriesCard({super.key, required this.week, this.clock, this.onCompleteProfile});

  @override
  State<WeekCaloriesCard> createState() => _WeekCaloriesCardState();
}

class _WeekCaloriesCardState extends State<WeekCaloriesCard> {
  static const _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _green = AppTheme.primaryStart;
  static const _amber = Color(0xFFF59E0B);

  DayCalories? _selected;

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final now = (widget.clock ?? DateTime.now)();
    final today = DateTime(now.year, now.month, now.day);
    final limit = week.dailyLimit;
    final maxValue = math.max(
      limit ?? 0,
      week.days.fold<int>(0, (m, d) => math.max(m, d.totalConsumed)),
    ).clamp(1, 1 << 31);

    final footer = limit == null
        ? 'Promedio: ${formatKcal(week.average)} kcal/día'
        : 'Promedio: ${formatKcal(week.average)} kcal/día · ${week.daysOnTarget} de 7 días en tu meta';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Esta semana',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              if (_selected != null)
                Text(
                  '${_weekdays[_selected!.date.weekday - 1]} ${_selected!.date.day} · '
                  '${formatKcal(_selected!.totalConsumed)} kcal',
                  style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                if (limit != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20 + 110 * (limit / maxValue),
                    child: const _DashedLine(),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final day in week.days)
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey(
                            'week-bar-${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selected = day),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 18,
                                height: math.max(4, 110 * (day.totalConsumed / maxValue)),
                                decoration: BoxDecoration(
                                  color: limit != null && day.totalConsumed > limit
                                      ? _amber
                                      : (day.date == today ? _green : _green.withValues(alpha: 0.45)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _initials[day.date.weekday - 1],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: day.date == today ? FontWeight.w900 : FontWeight.w600,
                                  color: day.date == today ? _green : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            footer,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (limit == null)
            TextButton(
              onPressed: widget.onCompleteProfile,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Completa tu perfil'),
            ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          children: List.generate(
            count,
            (i) => Container(
              width: 4,
              height: 1.5,
              margin: const EdgeInsets.only(right: 4),
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: `WeeklySummaryGrid`**

`lib/features/progress/presentation/widgets/weekly_summary_grid.dart` — 4 mosaicos simples (sin reutilizar el privado `_AverageTile`):

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/week_stats.dart';
import 'week_calories_card.dart' show formatKcal;

class WeeklySummaryGrid extends StatelessWidget {
  final WeekStats week;

  const WeeklySummaryGrid({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final limit = week.dailyLimit;
    final tiles = [
      ('PROMEDIO DIARIO', '${formatKcal(week.average)} kcal'),
      ('META DIARIA', limit == null ? '--' : '${formatKcal(limit)} kcal'),
      ('DÍAS EN META', limit == null ? '--' : '${week.daysOnTarget} de 7'),
      ('TOTAL SEMANA', '${formatKcal(week.total)} kcal'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: [
        for (final (label, value) in tiles)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.ambientShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
              ],
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 6: Repositorio y pantalla**

En `progress_repository.dart`:
- `import '../../../core/utils/local_date.dart';` y `import 'week_stats.dart';`.
- `ProgressData`: campo `final WeekStats? week;` y `this.week` en el constructor (opcional).
- `fetchProgress({DateTime? now})`: `final date = localDateString(now);`; pasar `query: {'date': date}` a las dos rutas de stats y agregar `final weekData = await _getOptionalMap(ApiRoutes.statsWeek, query: {'end': date});` y `week: weekData == null ? null : WeekStats.fromJson(weekData)`.
- `_getOptionalMap(String route, {Map<String, dynamic>? query})` y `_getData(String route, {Map<String, dynamic>? query})` pasan `queryParameters: query` al `_dio.get`.

En `progress_screen.dart`:
- `ProgressScreen` gana `@visibleForTesting final ProgressRepository? repository;` (constructor `this.repository`); `initState` usa `widget.repository ?? ProgressRepository()` y `MealLogState.instance.addListener(_onMealLogged)`; `dispose` lo quita. `_onMealLogged` hace `if (mounted) setState(() => _progressFuture = _repository.fetchProgress());`.
- En `_ProgressContent`, después de `_TodayCaloriesCard` y su separador, insertar:

```dart
          if (data.week != null) ...[
            WeekCaloriesCard(
              week: data.week!,
              // Sin meta faltan edad, altura o peso: se completan en el perfil.
              onCompleteProfile: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: UserProfile.fromJson(data.profile)),
                  ),
                );
                if (updated == true) MealLogState.instance.bump();
              },
            ),
            const SizedBox(height: 22),
          ],
```

Imports en `progress_screen.dart`: `../../../profile/presentation/screens/edit_profile_screen.dart`, `../../../profile/data/profile_repository.dart` (`UserProfile`), `../../../../core/state/meal_log_state.dart`, y los dos widgets nuevos.

- Reemplazar `_NutritionAveragesGrid(data: data)` por `data.week == null ? _NutritionAveragesGrid(data: data) : WeeklySummaryGrid(week: data.week!)`, y el título "Resumen nutricional" por "Resumen de la semana" cuando `data.week != null`.

- [ ] **Step 7: Correr tests**

Run: `flutter test test/features/progress`
Expected: PASS. Luego `flutter test` completo: PASS.

- [ ] **Step 8: Commit**

```bash
git add nutrilife/lib/features/progress nutrilife/test/features/progress
git commit -m "feat(progreso): semana de calorías y resumen semanal con fecha local"
```

---

### Task 9: Registrar peso y mini línea de pesos

**Files:**
- Create: `nutrilife/lib/features/progress/presentation/widgets/register_weight_sheet.dart`, `nutrilife/lib/features/progress/presentation/widgets/weight_sparkline.dart`
- Modify: `nutrilife/lib/features/progress/data/progress_repository.dart`, `nutrilife/lib/features/progress/presentation/screens/progress_screen.dart` (`_WeightInsightCard`, borrar `_InsightChartPainter`)
- Test: `nutrilife/test/features/progress/register_weight_sheet_test.dart`

**Interfaces:**
- Consumes: `POST /user/physical` (`ApiRoutes.userPhysical`), `MealLogState`, `ProgressData.currentWeight`, `ProgressData.currentHeight`, `ProgressData.orderedHistory`.
- Produces:
  - `Future<void> ProgressRepository.addWeight({required double weight, required double height})` — lanza `ProgressException` con el mensaje del backend.
  - `Future<bool> showRegisterWeightSheet(BuildContext context, {double? lastWeight, double? height, ProgressRepository? repository})` — `true` si guardó; al guardar llama `MealLogState.instance.bump()`.
  - `class WeightSparkline extends StatelessWidget { WeightSparkline({required List<double> weights}); }` — no dibuja nada con menos de 2.

- [ ] **Step 1: Test (falla)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/progress/data/progress_repository.dart';
import 'package:nutrilife/features/progress/presentation/widgets/register_weight_sheet.dart';

class _RepoFalso extends ProgressRepository {
  final saved = <(double, double)>[];

  @override
  Future<void> addWeight({required double weight, required double height}) async {
    saved.add((weight, height));
  }
}

Future<_RepoFalso> _open(WidgetTester tester, {double? weight = 80, double? height = 175}) async {
  final repo = _RepoFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showRegisterWeightSheet(context, lastWeight: weight, height: height, repository: repo),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('precarga el último peso y ajusta de a 0,1', (tester) async {
    final repo = await _open(tester);
    expect(find.text('80.0'), findsOneWidget);

    await tester.tap(find.byTooltip('Sumar 0,1 kg'));
    await tester.pump();
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    expect(repo.saved.single, (80.1, 175.0));
  });

  testWidgets('rechaza pesos fuera de rango', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(find.byKey(const ValueKey('weight-field')), '20');
    await tester.tap(find.text('Guardar peso'));
    await tester.pump();

    expect(find.text('El peso debe estar entre 30 y 300 kg'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('sin altura en el perfil la pide', (tester) async {
    final repo = await _open(tester, height: null);
    await tester.enterText(find.byKey(const ValueKey('height-field')), '170');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    expect(repo.saved.single, (80.0, 170.0));
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/progress/register_weight_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Repositorio**

En `ProgressRepository`:

```dart
  Future<void> addWeight({required double weight, required double height}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiRoutes.userPhysical,
        data: {'weight': weight, 'height': height},
      );
    } on DioException catch (error) {
      throw ProgressException(
        error.response?.data?['message']?.toString() ?? 'No se pudo guardar tu peso.',
      );
    }
  }
```

- [ ] **Step 4: Hoja**

`lib/features/progress/presentation/widgets/register_weight_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/state/meal_log_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/progress_repository.dart';

const double _minWeight = 30;
const double _maxWeight = 300;

Future<bool> showRegisterWeightSheet(
  BuildContext context, {
  double? lastWeight,
  double? height,
  ProgressRepository? repository,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _RegisterWeightSheet(
      lastWeight: lastWeight,
      height: height,
      repository: repository ?? ProgressRepository(),
    ),
  );
  if (saved == true) MealLogState.instance.bump();
  return saved == true;
}

class _RegisterWeightSheet extends StatefulWidget {
  final double? lastWeight;
  final double? height;
  final ProgressRepository repository;

  const _RegisterWeightSheet({this.lastWeight, this.height, required this.repository});

  @override
  State<_RegisterWeightSheet> createState() => _RegisterWeightSheetState();
}

class _RegisterWeightSheetState extends State<_RegisterWeightSheet> {
  late final TextEditingController _weight =
      TextEditingController(text: (widget.lastWeight ?? 70).toStringAsFixed(1));
  final TextEditingController _height = TextEditingController();
  String? _error;
  bool _saving = false;

  double? get _parsedWeight => double.tryParse(_weight.text.replaceAll(',', '.'));

  void _step(double delta) {
    final current = _parsedWeight ?? widget.lastWeight ?? 70;
    final next = ((current + delta) * 10).round() / 10;
    _weight.text = next.clamp(_minWeight, _maxWeight).toStringAsFixed(1);
    setState(() {});
  }

  Future<void> _save() async {
    final weight = _parsedWeight;
    if (weight == null || weight < _minWeight || weight > _maxWeight) {
      setState(() => _error = 'El peso debe estar entre 30 y 300 kg');
      return;
    }
    final height = widget.height ?? double.tryParse(_height.text.replaceAll(',', '.'));
    if (height == null || height <= 0 || height > 300) {
      setState(() => _error = 'Ingresa tu altura en cm');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addWeight(weight: weight, height: height);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar peso',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Restar 0,1 kg',
                  onPressed: () => _step(-0.1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('weight-field'),
                    controller: _weight,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryStart),
                    decoration: const InputDecoration(border: InputBorder.none, suffixText: 'kg'),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Sumar 0,1 kg',
                  onPressed: () => _step(0.1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (widget.height == null) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('height-field'),
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Altura (cm)',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryStart,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                child: const Text('Guardar peso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Nota sobre el test "precarga": el campo muestra `80.0`; tras "Sumar 0,1 kg" queda `80.1` y se guarda `(80.1, 175.0)`.

- [ ] **Step 5: Mini línea y botón en la tarjeta**

`lib/features/progress/presentation/widgets/weight_sparkline.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Línea con los últimos pesos. Con menos de 2 no hay tendencia que mostrar.
class WeightSparkline extends StatelessWidget {
  final List<double> weights;

  const WeightSparkline({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.length < 2) return const SizedBox.shrink();
    return CustomPaint(painter: _SparklinePainter(weights));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> weights;

  _SparklinePainter(this.weights);

  @override
  void paint(Canvas canvas, Size size) {
    final minW = weights.reduce(math.min);
    final maxW = weights.reduce(math.max);
    final range = (maxW - minW).abs() < 0.01 ? 1 : maxW - minW;
    final path = Path();
    for (var i = 0; i < weights.length; i++) {
      final x = size.width * i / (weights.length - 1);
      final y = size.height - (size.height * (weights[i] - minW) / range);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryStart.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.weights != weights;
}
```

En `_WeightInsightCard.build`:
- Reemplazar `CustomPaint(painter: _InsightChartPainter())` por:

```dart
              child: WeightSparkline(
                weights: data.orderedHistory
                    .map((r) => r.weight)
                    .whereType<double>()
                    .toList()
                    .reversed
                    .take(7)
                    .toList()
                    .reversed
                    .toList(),
              ),
```

- Después del texto de ayuda ("Comparado con…"/"Registra otro peso…"), agregar:

```dart
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showRegisterWeightSheet(
                  context,
                  lastWeight: data.currentWeight,
                  height: data.currentHeight,
                ),
                icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                label: const Text('Registrar peso'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ProgressScreen._green,
                  side: const BorderSide(color: Color(0xFFD1E7DA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
```

- Borrar la clase `_InsightChartPainter`. Imports de los dos widgets nuevos. `ProgressScreen` ya recarga por `MealLogState` (Task 8).
- Verificar que `currentHeight` devuelve centímetros (si devuelve metros ≤ 3, el backend acepta ambos: `stats.service` normaliza; `POST /user/physical` solo exige > 0).

- [ ] **Step 6: Correr tests**

Run: `flutter test test/features/progress`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add nutrilife/lib/features/progress nutrilife/test/features/progress/register_weight_sheet_test.dart
git commit -m "feat(progreso): registrar peso y mini línea con los últimos pesos"
```

---

### Task 10: Pantalla Premium (visual)

**Files:**
- Create: `nutrilife/lib/features/premium/presentation/screens/premium_screen.dart`, `nutrilife/lib/features/premium/presentation/widgets/premium_promo_card.dart`
- Modify: `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart` (`_SettingsCard`), `nutrilife/lib/features/progress/presentation/screens/progress_screen.dart` (al final de `_ProgressContent`)
- Test: `nutrilife/test/features/premium/premium_screen_test.dart`

**Interfaces:**
- Produces:
  - `class PremiumScreen extends StatefulWidget { const PremiumScreen({super.key}); }`; constantes `kPremiumMonthlyPrice = '\$4.99'`, `kPremiumYearlyPrice = '\$29.99'`, `kPremiumBenefits` (lista de 4 textos).
  - `class PremiumPromoCard extends StatelessWidget { const PremiumPromoCard({super.key}); }` — al tocar abre `PremiumScreen`.

- [ ] **Step 1: Test (falla)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';

void main() {
  testWidgets('el anual viene elegido y se puede cambiar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PremiumScreen()));

    expect(find.text('Ahorra 50%'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-yearly-selected')), findsOneWidget);

    await tester.tap(find.text('Mensual'));
    await tester.pump();
    expect(find.byKey(const ValueKey('plan-monthly-selected')), findsOneWidget);
  });

  testWidgets('pagar todavía no cobra', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PremiumScreen()));

    await tester.tap(find.text('Empezar 7 días gratis'));
    await tester.pump();
    expect(find.text('Los pagos llegan pronto'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/features/premium`
Expected: FAIL.

- [ ] **Step 3: Implementar la pantalla**

`lib/features/premium/presentation/screens/premium_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Precios y textos de ejemplo: todavía no hay cobro.
const kPremiumMonthlyPrice = '\$4.99';
const kPremiumYearlyPrice = '\$29.99';
const kPremiumBenefits = [
  'Chef IA sin límite de mensajes',
  'Historial de progreso completo',
  'Planes de comida semanales',
  'Recetas guardadas sin límite',
];

enum _Plan { monthly, yearly }

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  _Plan _plan = _Plan.yearly;

  void _soon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Los pagos llegan pronto')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C2F31),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Center(
            child: ClipOval(
              child: Image.asset('assets/images/nutria_logo.png', width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NutriLife Premium',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lleva tu alimentación al siguiente nivel',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final benefit in kPremiumBenefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryStart),
                  const SizedBox(width: 12),
                  Expanded(child: Text(benefit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Anual',
            price: '$kPremiumYearlyPrice / año',
            badge: 'Ahorra 50%',
            selected: _plan == _Plan.yearly,
            selectedKey: const ValueKey('plan-yearly-selected'),
            onTap: () => setState(() => _plan = _Plan.yearly),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Mensual',
            price: '$kPremiumMonthlyPrice / mes',
            selected: _plan == _Plan.monthly,
            selectedKey: const ValueKey('plan-monthly-selected'),
            onTap: () => setState(() => _plan = _Plan.monthly),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _soon,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: const Text('Empezar 7 días gratis'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: _soon, child: const Text('Restaurar compras')),
              const Text('·'),
              TextButton(onPressed: _soon, child: const Text('Términos')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final bool selected;
  final Key selectedKey;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    this.badge,
    required this.selected,
    required this.selectedKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        key: selected ? selectedKey : null,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryStart : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.primaryStart : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(price, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: AppTheme.primaryStart, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Entradas**

`lib/features/premium/presentation/widgets/premium_promo_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/premium_screen.dart';

class PremiumPromoCard extends StatelessWidget {
  const PremiumPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryStart),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Desbloquea tu progreso completo',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryStart),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.primaryStart),
          ],
        ),
      ),
    );
  }
}
```

- En `_ProgressContent`, al final de la `Column`: `const SizedBox(height: 24), const PremiumPromoCard(),`.
- En `_SettingsCard` de `profile_screen.dart`, primera fila:

```dart
          _SettingsRow(
            icon: Icons.workspace_premium_rounded,
            iconColor: _ProfileColors.green,
            iconBackground: const Color(0xFFDCFCE7),
            title: 'NutriLife Premium',
            subtitle: 'Planes y beneficios',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB4BC), size: 30),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
          ),
```

con el import `../../../premium/presentation/screens/premium_screen.dart`.

- [ ] **Step 5: Correr tests**

Run: `flutter test test/features/premium` y luego `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/premium nutrilife/lib/features/profile nutrilife/lib/features/progress nutrilife/test/features/premium
git commit -m "feat(premium): pantalla de planes solo visual con entradas en Perfil y Progreso"
```

---

### Task 11: Verificación final y despliegue

**Files:** ninguno nuevo.

- [ ] **Step 1: Suite completa y análisis**

```bash
cd nutrilife && flutter analyze lib test && flutter test
```

Expected: solo el aviso preexistente de `api_base_url.dart`; todos los tests PASS.

- [ ] **Step 2: Backend contra la base (tras push y despliegue)**

Con un token de prueba del usuario (no pegarlo en el chat), verificar en orden: `POST /meals {date}` → `POST /meals/:id/items` con `meal_type` → `GET /meals/day?date=` lo muestra → `GET /stats/week?end=` incluye las kcal → `DELETE /meals/items/:id` → `GET /meals/day` ya no lo muestra. Y que `POST /meals/<id de otro usuario>/items` responde 404.

- [ ] **Step 3: Prueba manual en el dispositivo (la hace el usuario)**

Lista para el usuario: agregar un alimento desde Alimentos (hoja, Deshacer), "Comidas de hoy" se actualiza sin refrescar, agregar desde el + de Cena, borrar desde el detalle, "Ver historial" ◀ ▶, Progreso muestra kcal de hoy y la semana, Registrar peso actualiza la tarjeta y el historial, Premium desde Perfil y desde Progreso.

- [ ] **Step 4: Subir la app** cuando el usuario apruebe: `git push origin main`.
