# Racha de agua en el backend: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Guardar los vasos de agua de cada día en la base de datos, para que la racha y los gráficos de hidratación sean los mismos en cualquier dispositivo.

**Architecture:**
- El backend solo guarda: tabla `water_intake`, con una fila por usuario y día, y el módulo `hydration`, que expone `GET` del historial, sumar y deshacer un vaso, e importar el historial local.
- La app sigue calculando la racha con el código actual de `WaterStreakRepository`. Lo único que cambia es de dónde salen los datos: la API en lugar de `SharedPreferences`.
- El historial local se sube una sola vez y se borra del teléfono.

**Tech Stack:** Node/Express ESM + `pg` + `node --test` con `mock.module`; Flutter + Dio + `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-17-agua-en-backend-design.md`

## Global Constraints

- Meta fija: **4 vasos al día** (`WaterStreakRepository.dailyGoal = 4`; en el backend, `DAILY_GOAL = 4`).
- El historial local viejo acepta hasta **5**, que se guarda como 4.
- Día = fecha local `YYYY-MM-DD` que manda la app. El backend acepta `date` a ±1 día de su fecha UTC. En el import, las fechas no pueden pasar de la fecha UTC del servidor + 1 día.
- El import acepta **1.000 entradas como máximo**.
- Rutas: `GET /api/v1/hydration`, `POST /api/v1/hydration/glass`, `POST /api/v1/hydration/glass/undo`, `POST /api/v1/hydration/import`, todas con `authenticateToken(['USER', 'ADMIN'])`.
- Todo texto que ve el usuario va en español e inglés:
  - backend: `SOURCE_MESSAGES` en `src/i18n/messages.js`, que el test `test/i18n/coverage.test.js` exige para cada `message: '...'` de un `.validation.js`;
  - app: los ARB.
- Commits **sin** `Co-Authored-By`. `git add` por ruta, nunca `-A`. Nunca commitear `nutrilife/macos/Flutter/GeneratedPluginRegistrant.swift`.
- No hacer push ni aplicar SQL en producción: lo hace el controlador después de preguntarle al usuario.

## Mapa de archivos

Backend:
- Crear `src/database/backups/update_17_10_2026_water_intake.sql`
- Crear `src/modules/hydration/hydration.repository.js`, `hydration.service.js`, `hydration.validation.js`, `hydration.controller.js` y `hydration.routes.js`
- Modificar `src/app.js` (montar las rutas)
- Modificar `src/modules/user/user.repository.js` (borrar el agua al eliminar la cuenta)
- Modificar `src/i18n/messages.js` (mensajes de validación)
- Tests: `test/hydration/hydration.validation.test.js` y `test/hydration/hydration.service.test.js`

App:
- Modificar `lib/core/network/api_routes.dart`
- Modificar `lib/features/hydration/data/water_streak_repository.dart`
- Modificar `lib/l10n/app_es.arb` y `app_en.arb` (`hydrationErrorLoad`) y regenerar
- Crear `test/helpers/fake_hydration_server.dart`
- Crear `test/flutter_test_config.dart` (instala el servidor falso en todos los tests)
- Modificar `test/features/hydration/water_streak_repository_test.dart`

---

### Task 1: Backend: tabla, repositorio, servicio y validación

**Files:**
- Create: `backend/src/database/backups/update_17_10_2026_water_intake.sql`
- Create: `backend/src/modules/hydration/hydration.repository.js`
- Create: `backend/src/modules/hydration/hydration.service.js`
- Create: `backend/src/modules/hydration/hydration.validation.js`
- Modify: `backend/src/i18n/messages.js` (SOURCE_MESSAGES, en orden alfabético con los demás)
- Modify: `backend/src/modules/user/user.repository.js` (dentro de `deleteUserAccountData`, junto a `DELETE FROM physical_records`)
- Test: `backend/test/hydration/hydration.validation.test.js`, `backend/test/hydration/hydration.service.test.js`

**Interfaces:**
- Produces:
  - `DAILY_GOAL = 4`; `MAX_LEGACY_GLASSES = 5`
  - `isValidDay(value): boolean`
  - `getHistoryService(userId) → { goal, history: Record<string, number> }`
  - `addGlassService(userId, date) → { date, glasses }`
  - `undoGlassService(userId, date) → { date, glasses }`
  - `importHistoryService(userId, history) → { imported }`
  - Middlewares `validateDayBody` (deja `req.hydrationDate`) y `validateImportBody` (deja `req.hydrationHistory`).

- [ ] **Step 1: SQL**

`backend/src/database/backups/update_17_10_2026_water_intake.sql`:

```sql
-- Racha de agua guardada en la base (spec 2026-10-17-agua-en-backend-design.md).
-- Una fila por usuario y día con vasos tomados (1 a 4). Un día sin vasos no
-- tiene fila. day es la fecha local del usuario, la que manda la app.

CREATE TABLE IF NOT EXISTS water_intake (
    user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    day         DATE NOT NULL,
    glasses     SMALLINT NOT NULL CHECK (glasses BETWEEN 1 AND 4),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, day)
);
```

- [ ] **Step 2: Tests que fallan**

`backend/test/hydration/hydration.validation.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { validateDayBody, validateImportBody, isValidDay } = await import(
  src('modules/hydration/hydration.validation.js')
);

const today = new Date().toISOString().slice(0, 10);
const shift = (days) => new Date(Date.now() + days * 86_400_000).toISOString().slice(0, 10);

const run = (validator, body) => {
  const req = { body };
  let nextArg = 'not-called';
  validator(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, error: nextArg };
};

test('isValidDay acepta solo fechas reales YYYY-MM-DD', () => {
  assert.equal(isValidDay('2026-10-17'), true);
  assert.equal(isValidDay('2026-02-30'), false);
  assert.equal(isValidDay('17/10/2026'), false);
  assert.equal(isValidDay(20261017), false);
});

test('date de hoy, ayer o mañana pasa', () => {
  for (const date of [today, shift(-1), shift(1)]) {
    const { req, error } = run(validateDayBody, { date });
    assert.equal(error, undefined);
    assert.equal(req.hydrationDate, date);
  }
});

for (const body of [{}, { date: 'hoy' }, { date: shift(-3) }, { date: shift(3) }, undefined]) {
  test(`date inválida ${JSON.stringify(body)} responde 400`, () => {
    const { error } = run(validateDayBody, body);
    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'date');
  });
}

test('import válido pasa y recorta 5 a 4', () => {
  const { req, error } = run(validateImportBody, { history: { [shift(-1)]: 5, [today]: 2 } });
  assert.equal(error, undefined);
  assert.deepEqual(req.hydrationHistory, { [shift(-1)]: 4, [today]: 2 });
});

for (const history of [
  undefined,
  [],
  'x',
  { 'no-es-fecha': 2 },
  { [today]: 0 },
  { [today]: 6 },
  { [today]: 2.5 },
  { [shift(5)]: 2 },
]) {
  test(`import inválido ${JSON.stringify(history)} responde 400`, () => {
    const { error } = run(validateImportBody, { history });
    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'history');
  });
}

test('import con más de 1000 días responde 400', () => {
  const history = {};
  for (let i = 0; i < 1001; i++) history[shift(-i - 1)] = 1;
  const { error } = run(validateImportBody, { history });
  assert.equal(error.status, 400);
});
```

`backend/test/hydration/hydration.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const repo = {};
mock.module(src('modules/hydration/hydration.repository.js'), {
  exports: {
    findWaterHistory: (...args) => repo.findWaterHistory(...args),
    addWaterGlass: (...args) => repo.addWaterGlass(...args),
    undoWaterGlass: (...args) => repo.undoWaterGlass(...args),
    importWaterHistory: (...args) => repo.importWaterHistory(...args),
  },
});

const { getHistoryService, addGlassService, undoGlassService, importHistoryService } = await import(
  src('modules/hydration/hydration.service.js')
);

beforeEach(() => {
  for (const key of Object.keys(repo)) delete repo[key];
});

test('el historial devuelve la meta y los días como objeto', async () => {
  repo.findWaterHistory = async () => [
    { day: '2026-10-16', glasses: 4 },
    { day: '2026-10-17', glasses: 2 },
  ];
  assert.deepEqual(await getHistoryService(7), {
    goal: 4,
    history: { '2026-10-16': 4, '2026-10-17': 2 },
  });
});

test('sumar un vaso devuelve el conteo del día', async () => {
  repo.addWaterGlass = async (userId, date, goal) => {
    assert.deepEqual([userId, date, goal], [7, '2026-10-17', 4]);
    return 3;
  };
  assert.deepEqual(await addGlassService(7, '2026-10-17'), { date: '2026-10-17', glasses: 3 });
});

test('deshacer el último vaso devuelve 0', async () => {
  repo.undoWaterGlass = async () => 0;
  assert.deepEqual(await undoGlassService(7, '2026-10-17'), { date: '2026-10-17', glasses: 0 });
});

test('el import manda los días y cuenta cuántos', async () => {
  let received;
  repo.importWaterHistory = async (userId, entries) => {
    received = { userId, entries };
  };
  const result = await importHistoryService(7, { '2026-10-16': 4, '2026-10-17': 1 });
  assert.deepEqual(result, { imported: 2 });
  assert.deepEqual(received, {
    userId: 7,
    entries: [
      { day: '2026-10-16', glasses: 4 },
      { day: '2026-10-17', glasses: 1 },
    ],
  });
});

test('un import vacío no toca la base', async () => {
  repo.importWaterHistory = async () => assert.fail('no debe llamarse');
  assert.deepEqual(await importHistoryService(7, {}), { imported: 0 });
});
```

Run: `cd backend && node --experimental-test-module-mocks --test test/hydration/*.test.js`
Expected: FAIL (`Cannot find module .../hydration.validation.js` y `.../hydration.service.js`).

- [ ] **Step 3: Implementar**

`backend/src/modules/hydration/hydration.repository.js`:

```js
import pool from '../../database/connection.js';

/** Todos los días con vasos de un usuario, del más viejo al más nuevo. */
export const findWaterHistory = async (userId) => {
  const { rows } = await pool.query(
    `SELECT to_char(day, 'YYYY-MM-DD') AS day, glasses
       FROM water_intake
      WHERE user_id = $1
      ORDER BY day`,
    [userId]
  );
  return rows;
};

/** Suma un vaso al día (tope `goal`). Devuelve los vasos del día. */
export const addWaterGlass = async (userId, day, goal) => {
  const { rows } = await pool.query(
    `INSERT INTO water_intake (user_id, day, glasses)
     VALUES ($1, $2::date, 1)
     ON CONFLICT (user_id, day)
     DO UPDATE SET glasses = LEAST(water_intake.glasses + 1, $3), updated_at = NOW()
     RETURNING glasses`,
    [userId, day, goal]
  );
  return rows[0].glasses;
};

/**
 * Resta un vaso al día; con el último, la fila se borra. Las dos sentencias
 * ven la misma foto de la fila, así que solo una actúa.
 * @returns {Promise<number>} vasos que quedan ese día.
 */
export const undoWaterGlass = async (userId, day) => {
  const { rows } = await pool.query(
    `WITH removed AS (
       DELETE FROM water_intake
        WHERE user_id = $1 AND day = $2::date AND glasses <= 1
     )
     UPDATE water_intake
        SET glasses = glasses - 1, updated_at = NOW()
      WHERE user_id = $1 AND day = $2::date AND glasses > 1
      RETURNING glasses`,
    [userId, day]
  );
  return rows[0]?.glasses ?? 0;
};

/** Sube días del historial local; por día se queda el mayor valor. */
export const importWaterHistory = async (userId, entries) => {
  await pool.query(
    `INSERT INTO water_intake (user_id, day, glasses)
     SELECT $1, d, g FROM unnest($2::date[], $3::smallint[]) AS t(d, g)
     ON CONFLICT (user_id, day)
     DO UPDATE SET glasses = GREATEST(water_intake.glasses, EXCLUDED.glasses), updated_at = NOW()`,
    [userId, entries.map((e) => e.day), entries.map((e) => e.glasses)]
  );
};
```

`backend/src/modules/hydration/hydration.service.js`:

```js
import { AppError } from '../../utils/AppError.js';
import {
  addWaterGlass,
  findWaterHistory,
  importWaterHistory,
  undoWaterGlass,
} from './hydration.repository.js';

export const DAILY_GOAL = 4;

const wrap = async (fn) => {
  try {
    return await fn();
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'HYDRATION_SERVICE_ERROR');
  }
};

/** Historial completo del usuario: { goal, history: { 'YYYY-MM-DD': vasos } }. */
export const getHistoryService = (userId) =>
  wrap(async () => {
    const rows = await findWaterHistory(userId);
    return {
      goal: DAILY_GOAL,
      history: Object.fromEntries(rows.map((row) => [row.day, Number(row.glasses)])),
    };
  });

export const addGlassService = (userId, date) =>
  wrap(async () => ({ date, glasses: Number(await addWaterGlass(userId, date, DAILY_GOAL)) }));

export const undoGlassService = (userId, date) =>
  wrap(async () => ({ date, glasses: Number(await undoWaterGlass(userId, date)) }));

/** El historial ya viene validado y recortado a la meta. */
export const importHistoryService = (userId, history) =>
  wrap(async () => {
    const entries = Object.entries(history).map(([day, glasses]) => ({ day, glasses }));
    if (entries.length > 0) await importWaterHistory(userId, entries);
    return { imported: entries.length };
  });
```

`backend/src/modules/hydration/hydration.validation.js`:

```js
import { AppError } from '../../utils/AppError.js';
import { DAILY_GOAL } from './hydration.service.js';

// El historial local viejo permitía 5 vasos; al importarlo se guarda como 4.
export const MAX_LEGACY_GLASSES = 5;
const MAX_IMPORT_DAYS = 1000;
const DAY_MS = 86_400_000;

const validationError = (field, message) =>
  new AppError('Validation error', 400, 'VALIDATION_ERROR', [{ field, message }]);

/** Fecha real en formato YYYY-MM-DD. */
export const isValidDay = (value) => {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const time = Date.parse(`${value}T00:00:00Z`);
  return !Number.isNaN(time) && new Date(time).toISOString().slice(0, 10) === value;
};

// Distancia en días entre `value` y el día UTC del servidor.
const daysFromServerToday = (value) => {
  const serverToday = Date.parse(`${new Date().toISOString().slice(0, 10)}T00:00:00Z`);
  return Math.round((Date.parse(`${value}T00:00:00Z`) - serverToday) / DAY_MS);
};

/** Valida { date } de sumar o deshacer un vaso. Adjunta req.hydrationDate. */
export const validateDayBody = (req, res, next) => {
  const { date } = req.body ?? {};
  // ±1 día cubre todas las zonas horarias sin dejar escribir días lejanos.
  if (!isValidDay(date) || Math.abs(daysFromServerToday(date)) > 1) {
    return next(validationError('date', 'date must be today in YYYY-MM-DD format'));
  }
  req.hydrationDate = date;
  next();
};

/** Valida { history } del import del historial local. Adjunta req.hydrationHistory. */
export const validateImportBody = (req, res, next) => {
  const { history } = req.body ?? {};
  if (!history || typeof history !== 'object' || Array.isArray(history)) {
    return next(validationError('history', 'history must be an object of date: glasses'));
  }
  const entries = Object.entries(history);
  if (entries.length > MAX_IMPORT_DAYS) {
    return next(validationError('history', 'history has too many days'));
  }
  const clean = {};
  for (const [day, glasses] of entries) {
    const validCount = Number.isInteger(glasses) && glasses >= 1 && glasses <= MAX_LEGACY_GLASSES;
    if (!isValidDay(day) || daysFromServerToday(day) > 1 || !validCount) {
      return next(validationError('history', 'history must be an object of date: glasses'));
    }
    clean[day] = Math.min(glasses, DAILY_GOAL);
  }
  req.hydrationHistory = clean;
  next();
};
```

En `backend/src/i18n/messages.js`, dentro de `SOURCE_MESSAGES` (sección de detalles de validación, en orden alfabético):

```js
  'date must be today in YYYY-MM-DD format': {
    es: 'date debe ser la fecha de hoy en formato YYYY-MM-DD.',
    en: 'date must be today in YYYY-MM-DD format.',
  },
  'history has too many days': {
    es: 'El historial tiene demasiados días.',
    en: 'The history has too many days.',
  },
  'history must be an object of date: glasses': {
    es: 'El historial debe ser un objeto fecha: vasos.',
    en: 'The history must be an object of date: glasses.',
  },
```

En `CODE_MESSAGES.en` (sección de errores internos): `HYDRATION_SERVICE_ERROR: SOMETHING_WENT_WRONG,`.

En `backend/src/modules/user/user.repository.js`, en `deleteUserAccountData`, justo después de `await client.query('DELETE FROM physical_records WHERE user_id = $1', [userId]);`:

```js
    await client.query('DELETE FROM water_intake WHERE user_id = $1', [userId]);
```

- [ ] **Step 4: Tests en verde**

Run: `cd backend && npm test`
Expected: PASS todos, incluido `test/i18n/coverage.test.js`.

- [ ] **Step 5: Commit**

```bash
git add backend/src/database/backups/update_17_10_2026_water_intake.sql backend/src/modules/hydration/hydration.repository.js backend/src/modules/hydration/hydration.service.js backend/src/modules/hydration/hydration.validation.js backend/src/i18n/messages.js backend/src/modules/user/user.repository.js backend/test/hydration/hydration.validation.test.js backend/test/hydration/hydration.service.test.js
git commit -m "feat(hidratacion): guardar los vasos de agua en la base"
```

---

### Task 2: Backend: rutas HTTP

**Files:**
- Create: `backend/src/modules/hydration/hydration.controller.js`
- Create: `backend/src/modules/hydration/hydration.routes.js`
- Modify: `backend/src/app.js` (import y `app.use('/api/v1/hydration', hydrationRoutes);` junto a las otras rutas)
- Test: `backend/test/hydration/hydration.controller.test.js`

**Interfaces:**
- Consumes: servicios y validaciones de la Task 1.
- Produces: las 4 rutas de las Global Constraints. Cada una responde `successResponse(res, data, msg)`.

- [ ] **Step 1: Test que falla**

`backend/test/hydration/hydration.controller.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const calls = [];
mock.module(src('modules/hydration/hydration.service.js'), {
  exports: {
    DAILY_GOAL: 4,
    getHistoryService: async (userId) => (calls.push(['get', userId]), { goal: 4, history: {} }),
    addGlassService: async (userId, date) => (calls.push(['add', userId, date]), { date, glasses: 1 }),
    undoGlassService: async (userId, date) => (calls.push(['undo', userId, date]), { date, glasses: 0 }),
    importHistoryService: async (userId, history) => (calls.push(['import', userId, history]), { imported: 1 }),
  },
});

const controller = await import(src('modules/hydration/hydration.controller.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => ((res.statusCode = code), res);
  res.json = (body) => ((res.body = body), res);
  return res;
};

test('cada handler llama a su servicio con el usuario del token', async () => {
  const user = { userId: 7 };
  const cases = [
    [controller.getHistory, { user }, { goal: 4, history: {} }],
    [controller.addGlass, { user, hydrationDate: '2026-10-17' }, { date: '2026-10-17', glasses: 1 }],
    [controller.undoGlass, { user, hydrationDate: '2026-10-17' }, { date: '2026-10-17', glasses: 0 }],
    [controller.importHistory, { user, hydrationHistory: { '2026-10-16': 4 } }, { imported: 1 }],
  ];
  for (const [handler, req, data] of cases) {
    const res = fakeRes();
    await handler(req, res, (error) => assert.fail(error));
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.body.data, data);
  }
  assert.deepEqual(calls, [
    ['get', 7],
    ['add', 7, '2026-10-17'],
    ['undo', 7, '2026-10-17'],
    ['import', 7, { '2026-10-16': 4 }],
  ]);
});
```

Run: `cd backend && node --experimental-test-module-mocks --test test/hydration/hydration.controller.test.js`
Expected: FAIL (no existe el controller).

- [ ] **Step 2: Implementar**

`backend/src/modules/hydration/hydration.controller.js`:

```js
import { successResponse } from '../../utils/response.js';
import {
  addGlassService,
  getHistoryService,
  importHistoryService,
  undoGlassService,
} from './hydration.service.js';

const handle = (run, message) => async (req, res, next) => {
  try {
    return successResponse(res, await run(req), message);
  } catch (error) {
    next(error);
  }
};

export const getHistory = handle((req) => getHistoryService(req.user.userId), 'Historial de agua obtenido');
export const addGlass = handle((req) => addGlassService(req.user.userId, req.hydrationDate), 'Vaso registrado');
export const undoGlass = handle((req) => undoGlassService(req.user.userId, req.hydrationDate), 'Vaso deshecho');
export const importHistory = handle(
  (req) => importHistoryService(req.user.userId, req.hydrationHistory),
  'Historial de agua importado'
);
```

`backend/src/modules/hydration/hydration.routes.js`:

```js
import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { addGlass, getHistory, importHistory, undoGlass } from './hydration.controller.js';
import { validateDayBody, validateImportBody } from './hydration.validation.js';

const router = Router();
const auth = authenticateToken(['USER', 'ADMIN']);

/**
 * @openapi
 * /api/v1/hydration:
 *   get:
 *     tags: [Hydration]
 *     summary: Historial de vasos de agua del usuario
 *     description: data = { goal, history: { "YYYY-MM-DD": vasos } }. La app calcula la racha.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Historial }
 */
router.get('/', auth, getHistory);

/**
 * @openapi
 * /api/v1/hydration/glass:
 *   post:
 *     tags: [Hydration]
 *     summary: Suma un vaso al día (tope 4)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { type: object, required: [date], properties: { date: { type: string, example: '2026-10-17' } } }
 *     responses:
 *       200: { description: '{ date, glasses }' }
 */
router.post('/glass', auth, validateDayBody, addGlass);

/**
 * @openapi
 * /api/v1/hydration/glass/undo:
 *   post:
 *     tags: [Hydration]
 *     summary: Deshace el último vaso del día
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: '{ date, glasses }' }
 */
router.post('/glass/undo', auth, validateDayBody, undoGlass);

/**
 * @openapi
 * /api/v1/hydration/import:
 *   post:
 *     tags: [Hydration]
 *     summary: Sube el historial que estaba guardado en el teléfono
 *     description: Por cada día se queda el mayor valor entre el teléfono y el servidor.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: '{ imported }' }
 */
router.post('/import', auth, validateImportBody, importHistory);

export default router;
```

En `backend/src/app.js`, agregar `import hydrationRoutes from './modules/hydration/hydration.routes.js';` junto a los otros imports de rutas y `app.use('/api/v1/hydration', hydrationRoutes);` junto a los otros `app.use('/api/v1/...')`.

- [ ] **Step 3: Verificar**

Run: `cd backend && npm test && node -e "import('./src/app.js').then(()=>{console.log('app ok');process.exit(0)})"`
Expected: suite en PASS y `app ok`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/modules/hydration/hydration.controller.js backend/src/modules/hydration/hydration.routes.js backend/src/app.js backend/test/hydration/hydration.controller.test.js
git commit -m "feat(hidratacion): rutas del historial de agua"
```

---

### Task 3: App: repositorio contra la API y subida del historial local

**Files:**
- Modify: `nutrilife/lib/core/network/api_routes.dart`
- Modify: `nutrilife/lib/features/hydration/data/water_streak_repository.dart`
- Modify: `nutrilife/lib/l10n/app_es.arb` y `app_en.arb` (+ `flutter gen-l10n`)
- Create: `nutrilife/test/helpers/fake_hydration_server.dart`
- Create: `nutrilife/test/flutter_test_config.dart`
- Modify: `nutrilife/test/features/hydration/water_streak_repository_test.dart`

**Interfaces:**
- Consumes: las rutas de la Task 2.
- Produces:
  - `WaterStreakRepository({required String accountId, Dio? dio})` con `load`, `addGlass` y `undoGlass`, los mismos de antes.
  - `FakeHydrationServer`: un `HttpClientAdapter` con `Map<String, int> history`, que delega lo que no es `/hydration` al adapter original.

- [ ] **Step 1: Servidor falso y configuración global de tests**

`nutrilife/test/helpers/fake_hydration_server.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Backend de hidratación en memoria, con las mismas reglas que el real:
/// tope de 4 vasos, borrar el día al deshacer el último e import que se
/// queda con el mayor valor. Lo que no es /hydration se pasa a [fallback].
class FakeHydrationServer implements HttpClientAdapter {
  FakeHydrationServer({this.fallback});

  static const int goal = 4;

  final HttpClientAdapter? fallback;
  final Map<String, int> history = {};
  final List<RequestOptions> requests = [];

  /// Si es true, todas las rutas de hidratación responden 500.
  bool failing = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.startsWith('/hydration')) {
      final next = fallback;
      if (next == null) return _json(404, {'success': false, 'message': 'not found'});
      return next.fetch(options, requestStream, cancelFuture);
    }
    requests.add(options);
    if (failing) return _json(500, {'success': false, 'message': 'boom'});

    final body = options.data is Map ? options.data as Map : const {};
    switch ((options.method, options.path)) {
      case ('GET', '/hydration'):
        return _ok({'goal': goal, 'history': history});
      case ('POST', '/hydration/glass'):
        final date = body['date'] as String;
        history[date] = ((history[date] ?? 0) + 1).clamp(1, goal);
        return _ok({'date': date, 'glasses': history[date]});
      case ('POST', '/hydration/glass/undo'):
        final date = body['date'] as String;
        final left = (history[date] ?? 0) - 1;
        if (left <= 0) {
          history.remove(date);
        } else {
          history[date] = left;
        }
        return _ok({'date': date, 'glasses': left < 0 ? 0 : left});
      case ('POST', '/hydration/import'):
        final incoming = (body['history'] as Map).cast<String, int>();
        for (final entry in incoming.entries) {
          final value = entry.value.clamp(1, goal);
          final current = history[entry.key] ?? 0;
          history[entry.key] = value > current ? value : current;
        }
        return _ok({'imported': incoming.length});
    }
    return _json(404, {'success': false, 'message': 'not found'});
  }

  ResponseBody _ok(Object data) => _json(200, {'success': true, 'data': data});

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
```

`nutrilife/test/flutter_test_config.dart` (Flutter lo corre antes de cada archivo de test):

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';

import 'helpers/fake_hydration_server.dart';

/// Los widgets de la racha de agua llaman al backend por DioClient.instance.
/// En los tests responde un servidor de hidratación en memoria, vacío al
/// empezar cada test, y el resto de las rutas sigue como siempre.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final original = DioClient.instance.httpClientAdapter;
  setUp(() {
    DioClient.instance.httpClientAdapter = FakeHydrationServer(fallback: original);
  });
  tearDown(() {
    DioClient.instance.httpClientAdapter = original;
  });
  await testMain();
}
```

- [ ] **Step 2: Reescribir los tests del repositorio (fallan)**

En `nutrilife/test/features/hydration/water_streak_repository_test.dart`:
- Agregar `import 'package:dio/dio.dart';` y `import '../../helpers/fake_hydration_server.dart';`.
- Agregar un helper:

```dart
WaterStreakRepository _repo(FakeHydrationServer server, {String account = 'user@example.com'}) =>
    WaterStreakRepository(
      accountId: account,
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = server,
    );
```

- En los tests "guarda el progreso diario y calcula rachas consecutivas" y "limita el conteo a cuatro y permite deshacer vasos", reemplazar `WaterStreakRepository(accountId: 'user@example.com')` por `_repo(FakeHydrationServer())`. Las expectativas se mantienen.
- Reemplazar "mantiene historiales separados por cuenta" por:

```dart
  test('cada cuenta ve su propio historial del servidor', () async {
    final first = _repo(FakeHydrationServer(), account: 'one@example.com');
    final second = _repo(FakeHydrationServer(), account: 'two@example.com');
    final today = DateTime(2026, 10, 14);

    await first.addGlass(now: today);

    expect((await first.load(now: today)).glassesToday, 1);
    expect((await second.load(now: today)).glassesToday, 0);
  });
```

- Reemplazar "migra historiales guardados con la meta anterior de cinco vasos" por:

```dart
  test('sube una vez el historial guardado en el teléfono y lo borra', () async {
    SharedPreferences.setMockInitialValues({
      'water_streak_v1_user%40example.com': '{"2026-10-11":4,"2026-10-12":5,"mal":2}',
    });
    final server = FakeHydrationServer();
    final repository = _repo(server);

    final snapshot = await repository.load(now: DateTime(2026, 10, 12));
    final preferences = await SharedPreferences.getInstance();

    expect(server.history, {'2026-10-11': 4, '2026-10-12': 4});
    expect(snapshot.currentStreak, 2);
    expect(preferences.getString('water_streak_v1_user%40example.com'), isNull);

    await repository.load(now: DateTime(2026, 10, 12));
    expect(server.requests.where((r) => r.path == '/hydration/import'), hasLength(1));
  });

  test('si el import falla, el historial local se queda para reintentar', () async {
    SharedPreferences.setMockInitialValues({
      'water_streak_v1_user%40example.com': '{"2026-10-12":3}',
    });
    final server = FakeHydrationServer()..failing = true;

    await expectLater(_repo(server).load(now: DateTime(2026, 10, 12)), throwsException);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('water_streak_v1_user%40example.com'), isNotNull);
  });
```

Run: `cd nutrilife && flutter test test/features/hydration/water_streak_repository_test.dart`
Expected: FAIL de compilación (el constructor no tiene `dio`).

- [ ] **Step 3: Implementar**

`nutrilife/lib/core/network/api_routes.dart`, junto a las otras:

```dart
  static const String hydration = '/hydration';
  static const String hydrationGlass = '/hydration/glass';
  static const String hydrationGlassUndo = '/hydration/glass/undo';
  static const String hydrationImport = '/hydration/import';
```

ARB:
- `app_es.arb`: `"hydrationErrorLoad": "No se pudo cargar tu racha de agua. Revisa tu conexión."`
- `app_en.arb`: `"hydrationErrorLoad": "Couldn't load your water streak. Check your connection."`
- Agregar al final de cada archivo, sin olvidar la coma en la línea anterior. Después: `cd nutrilife && flutter gen-l10n`.

En `water_streak_repository.dart`, `WaterStreakSnapshot`, `WaterStreakState` y los métodos `_snapshot`, `_currentStreak`, `_bestStreak`, `_previousDate` y `_nextDate` **no cambian**. Se reemplaza el resto de la clase `WaterStreakRepository`:

```dart
class WaterStreakRepository {
  WaterStreakRepository({required String accountId, Dio? dio})
    : _legacyKey =
          'water_streak_v1_${Uri.encodeComponent(accountId.trim().toLowerCase())}',
      _dio = dio ?? DioClient.instance;

  static const int dailyGoal = 4;
  static const int _legacyMaxGlasses = 5;

  /// Clave del historial que vivía solo en el teléfono, antes del backend.
  final String _legacyKey;
  final Dio _dio;

  Future<WaterStreakSnapshot> load({DateTime? now}) async {
    final today = localDateString(now);
    await _importLegacyHistory();
    return _snapshot(await _fetchHistory(), today);
  }

  Future<WaterStreakSnapshot> addGlass({DateTime? now}) =>
      _changeGlasses(ApiRoutes.hydrationGlass, now);

  Future<WaterStreakSnapshot> undoGlass({DateTime? now}) =>
      _changeGlasses(ApiRoutes.hydrationGlassUndo, now);

  Future<WaterStreakSnapshot> _changeGlasses(String route, DateTime? now) async {
    final today = localDateString(now);
    final history = await _fetchHistory();
    final int glasses;
    try {
      final response = await _dio.post<Map<String, dynamic>>(route, data: {'date': today});
      glasses = ((response.data?['data'] as Map?)?['glasses'] as num?)?.toInt() ?? 0;
    } on DioException {
      throw Exception(currentL10n.hydrationErrorSave);
    }
    if (glasses > 0) {
      history[today] = glasses;
    } else {
      history.remove(today);
    }
    WaterStreakState.instance.bump();
    return _snapshot(history, today);
  }

  Future<Map<String, int>> _fetchHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiRoutes.hydration);
      final raw = (response.data?['data'] as Map?)?['history'];
      if (raw is! Map) throw Exception(currentL10n.hydrationErrorInvalidHistory);
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } on DioException {
      throw Exception(currentL10n.hydrationErrorLoad);
    }
  }

  /// Sube una sola vez lo que estaba guardado en el teléfono. Si el servidor
  /// no responde, se deja para el próximo intento. Las entradas raras se
  /// descartan.
  Future<void> _importLegacyHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_legacyKey);
    if (stored == null) return;

    final history = <String, int>{};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final day = entry.key;
          final count = entry.value;
          final parsed = day is String ? DateTime.tryParse(day) : null;
          if (parsed == null || localDateString(parsed) != day) continue;
          if (count is! int || count < 1 || count > _legacyMaxGlasses) continue;
          history[day as String] = count;
        }
      }
    } on FormatException {
      // JSON roto: no hay nada que rescatar.
    }

    if (history.isNotEmpty) {
      try {
        await _dio.post<void>(ApiRoutes.hydrationImport, data: {'history': history});
      } on DioException {
        throw Exception(currentL10n.hydrationErrorLoad);
      }
    }
    await preferences.remove(_legacyKey);
  }
```

Agregar los imports `package:dio/dio.dart`, `../../../core/network/api_routes.dart` y `../../../core/network/dio_client.dart`. Se borran `_readHistory` y `_writeHistory`, y también los usos de `hydrationErrorInvalidData` y `hydrationErrorUpdate` (las claves pueden quedar en el ARB).

Nota: si el import falla, `load` lanza un error, la pantalla muestra el mensaje de error y el historial local se conserva, que es lo que espera el test.

- [ ] **Step 4: Tests en verde**

Run: `cd nutrilife && flutter test test/features/hydration/ && flutter analyze lib/features/hydration lib/core/network`
Expected: PASS y `No issues found!`.

- [ ] **Step 5: Commit (local)**

```bash
git add nutrilife/lib/core/network/api_routes.dart nutrilife/lib/features/hydration/data/water_streak_repository.dart nutrilife/lib/l10n/app_es.arb nutrilife/lib/l10n/app_en.arb nutrilife/lib/l10n/app_localizations.dart nutrilife/lib/l10n/app_localizations_es.dart nutrilife/lib/l10n/app_localizations_en.dart nutrilife/test/helpers/fake_hydration_server.dart nutrilife/test/flutter_test_config.dart nutrilife/test/features/hydration/water_streak_repository_test.dart
git commit -m "feat(hidratacion): la racha de agua se guarda en el backend"
```

---

### Task 4: App: suite completa con el servidor falso

**Files:**
- Modify (solo si hace falta): los tests de widgets que usan la racha. Son los de `test/features/hydration/`, `test/features/profile/`, `test/features/progress/` y `test/l10n/english_layout_test.dart`.

**Interfaces:**
- Consumes: `FakeHydrationServer` y `flutter_test_config.dart` de la Task 3.

- [ ] **Step 1: Suite completa**

Run: `cd nutrilife && flutter test`
Expected: PASS. Si algún test que antes sembraba el historial con `SharedPreferences.setMockInitialValues({'water_streak_v1_...': ...})` ahora espera ver esos vasos, va a seguir funcionando: el primer `load` los sube al servidor falso por el import.

Si algún test necesita historial ya cargado y no pasa por `load`, que siembre el servidor falso:

```dart
(DioClient.instance.httpClientAdapter as FakeHydrationServer).history['2026-10-12'] = 4;
```

- [ ] **Step 2: Análisis**

Run: `cd nutrilife && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Commit (local), solo si cambió algún test**

```bash
git add <los tests modificados>
git commit -m "test(hidratacion): los tests de widgets usan el servidor de agua en memoria"
```

---

## Despliegue (lo hace el controlador, con el OK del usuario)

1. `cd backend && npm run db:apply -- update_17_10_2026_water_intake.sql` (vista previa) y después con `--yes`.
2. Push del backend (Tasks 1 y 2).
3. Push de la app (Tasks 3 y 4) cuando el usuario lo apruebe. El backend tiene que estar desplegado antes de usar la app nueva.
