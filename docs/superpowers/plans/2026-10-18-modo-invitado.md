# Modo invitado — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un botón "Entrar como invitado" en el login que crea una cuenta real y temporal (24 h, plan FREE, datos de ejemplo) en el backend, y que se apaga con una variable de entorno al terminar la beta.

**Architecture:** El backend crea al invitado con `POST /auth/guest` (usuario con `guest_expires_at`, perfil y 7 días de datos de ejemplo en una transacción) y le da un token que vence justo cuando vence la cuenta. El middleware de auth distingue un token de invitado vencido (`GUEST_EXPIRED`), un middleware `rejectGuests` bloquea las rutas de compra y contraseña, y un job horario borra las cuentas vencidas con `deleteUserAccountData`. La app consulta `GET /auth/health` para mostrar el botón, guarda la sesión como cualquier login y lee `isGuest`/`guestExpiresAt` de `SessionService` para la franja del inicio y los bloqueos.

**Tech Stack:** Backend Node 22 + Express 5 + pg + `node:test` (con `mock.module`). App Flutter + Dio + ARB (`flutter gen-l10n`). Panel React + Vite + TypeScript.

**Spec:** `docs/superpowers/specs/2026-10-18-modo-invitado-design.md`

## Global Constraints

- Interruptor: `GUEST_MODE_ENABLED=true` lo enciende; apagado o sin definir, `POST /auth/guest` responde 404 (`GUEST_MODE_DISABLED`) y `GET /auth/health` devuelve `guestModeEnabled: false`. La limpieza de vencidos corre siempre.
- Duración: 24 horas (`GUEST_TTL_MS = 24 * 60 * 60 * 1000`).
- Plan del invitado: FREE. Sin compras ni restaurar compras.
- Correo del invitado: `guest-<uuid>@guest.nutrilife.invalid`. Contraseña NULL. `email_verified_at` = ahora.
- Rate limit de `POST /auth/guest`: 5 por hora por IP (`RATE_LIMIT_GUEST_PER_HOUR`, default 5).
- Una cuenta es de invitado si y solo si `users.guest_expires_at IS NOT NULL`.
- Todo texto que ve el usuario en la app va por ARB, en `app_es.arb` (plantilla) y `app_en.arb`.
- Todo código nuevo de `AppError` lleva su texto en inglés en `CODE_MESSAGES.en` (lo exige `test/i18n/coverage.test.js`).
- Commits sin línea `Co-Authored-By` de Claude.
- Seguir el estilo del archivo que se toca (los middlewares de `backend/src/middleware/auth.middleware.js` no usan punto y coma; el resto del backend sí).

## Ajustes al spec (encontrados al leer el código)

1. **Token de 24 h para el invitado.** Los tokens normales duran 1 h (`JWT_EXPIRES_IN = '1h'`) y la app no los renueva: manda al login. Un invitado no tiene contraseña, así que perdería la cuenta a la hora. Su token vence en `guest_expires_at`, y eso mismo hace el bloqueo: el middleware reconoce un token vencido con `isGuest: true` y responde `401 GUEST_EXPIRED`. No hace falta consultar la base en cada petición.
2. **El perfil no tiene "cambiar correo/contraseña" ni "vincular Google".** Solo "Eliminar cuenta", que pide contraseña o Google: el invitado no tiene ninguno de los dos. Para el invitado se oculta "Eliminar cuenta" (se borra sola). En el backend se bloquea `POST /user/password` (crear contraseña) y `POST /subscription/sync`.
3. **`/auth/google/link` no se bloquea.** Es una ruta sin token que busca por el correo de Google; nunca puede dar con un `@guest.nutrilife.invalid`.
4. **No hay columna de sexo.** El perfil de ejemplo es edad 28, objetivo `lose`, altura 170 y peso 72,4 → 71,8.
5. **`stats` es por usuario, no global.** Solo cambian el overview y la lista del panel.
6. **`isGuest` viaja en la sesión, no en `/user/profile`.** La app lo lee de `SessionService` (que guarda el usuario del login), así que el perfil del backend no cambia.

## Archivos

Backend (`backend/`):
- Create `src/database/backups/update_18_10_2026_guest_mode.sql` — columna `guest_expires_at` e índice.
- Modify `src/config/env_config.js` — `guestMode.enabled`, `rateLimit.guestPerHour`.
- Modify `src/i18n/messages.js` — textos en inglés de `GUEST_MODE_DISABLED`, `GUEST_EXPIRED`, `GUEST_NOT_ALLOWED`.
- Create `src/modules/auth/guest.sampleData.js` — perfil y datos de ejemplo (función pura).
- Create `src/modules/auth/guest.repository.js` — crea la cuenta con sus datos en una transacción; busca vencidos.
- Modify `src/modules/auth/auth.repository.js` — `guestExpiresAt` en `userSelect`.
- Modify `src/modules/auth/auth.service.js` — token y sesión de invitado, `loginAsGuest`, `guestModeEnabled` en el health.
- Modify `src/modules/auth/auth.controller.js`, `src/modules/auth/auth.routes.js` — `POST /auth/guest`.
- Modify `src/middleware/rateLimit.middleware.js` — `duration` configurable y `guestRateLimit`.
- Modify `src/middleware/auth.middleware.js` — `GUEST_EXPIRED` y `rejectGuests`.
- Modify `src/modules/user/user.routes.js`, `src/modules/subscription/subscription.routes.js` — `rejectGuests`.
- Create `src/modules/auth/guestCleanup.job.js`; modify `src/server.js`.
- Modify `src/modules/admin/admin.repository.js` — overview sin invitados, `authMethod = 'GUEST'`.
- Tests: create `test/auth/guest.sampleData.test.js`, `test/auth/guest.service.test.js`, `test/auth/auth.middleware.test.js`, `test/auth/guestCleanup.job.test.js`, `test/i18n/guestRateLimit.test.js`; modify `test/auth/auth.service.test.js` (mock del repositorio nuevo).

Panel (`admin-panel/`):
- Modify `src/types/admin.ts`, `src/components/CategoryBadge.tsx` — método `GUEST` con etiqueta "Invitado".

App (`nutrilife/`):
- Modify `lib/core/network/api_routes.dart` — `authGuest`.
- Modify `lib/features/auth/data/auth_repository.dart` — `isGuestModeEnabled`, `loginAsGuest`.
- Modify `lib/core/services/session_service.dart` — `isGuest`, `guestExpiresAt`, sin RevenueCat para invitados.
- Create `lib/features/auth/presentation/widgets/guest_notice_dialog.dart` — la alerta.
- Create `lib/features/auth/presentation/guest_sign_in_flow.dart` — crea la sesión y abre la app.
- Modify `lib/features/auth/presentation/screens/login_screen.dart` — botón, `notice`, `authRepository`.
- Modify `test/flutter_test_config.dart` — en los tests el botón no consulta la red.
- Create `lib/features/home/presentation/widgets/guest_banner.dart`; modify `lib/features/home/presentation/screens/dashboard_screen.dart`.
- Modify `lib/features/profile/presentation/screens/profile_screen.dart` — sin "Eliminar cuenta" para invitados.
- Modify `lib/features/premium/presentation/screens/premium_screen.dart` — compra y restaurar bloqueados.
- Modify `lib/core/network/dio_client.dart` — aviso de invitado vencido.
- Modify `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` (+ generados).
- Tests: create `test/features/auth/guest_login_test.dart`, `test/features/home/guest_banner_test.dart`; modify `test/core/services/session_service_test.dart`, `test/features/auth/auth_repository_google_test.dart`, `test/features/premium/premium_screen_test.dart`, `test/features/profile/profile_l10n_test.dart`, `test/core/network/dio_client_redirect_test.dart`.

## Antes de empezar

Trabajar en una rama: `git checkout -b feat/modo-invitado`. Si `main` tiene cambios sin commitear que no son de este plan, no se tocan ni se incluyen en los commits (cada commit hace `git add` solo de sus archivos).

---

### Task 1: Base, configuración y textos del backend

**Files:**
- Create: `backend/src/database/backups/update_18_10_2026_guest_mode.sql`
- Modify: `backend/src/config/env_config.js`
- Modify: `backend/src/i18n/messages.js` (bloque `CODE_MESSAGES.en`, junto a `UNAUTHORIZED`)

**Interfaces:**
- Produces: `config.guestMode.enabled` (boolean), `config.rateLimit.guestPerHour` (number). Columna `users.guest_expires_at TIMESTAMPTZ NULL`. Códigos `GUEST_MODE_DISABLED`, `GUEST_EXPIRED`, `GUEST_NOT_ALLOWED` con texto en inglés.

- [ ] **Step 1: Migración**

```sql
-- Modo invitado para la beta (spec 2026-10-18-modo-invitado-design.md).
-- guest_expires_at: hasta cuándo dura la cuenta de invitado. NULL = cuenta
-- normal. Al vencer, el job guestCleanup la borra con todos sus datos.
-- Columna nueva y nullable: no cambia a ningún usuario existente.

ALTER TABLE users ADD COLUMN IF NOT EXISTS guest_expires_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_guest_expires_at
    ON users (guest_expires_at)
    WHERE guest_expires_at IS NOT NULL;
```

- [ ] **Step 2: Configuración**

En `env_config.js`, dentro de `rateLimit` agregar después de `subscriptionSyncPerMinute`:

```js
    guestPerHour: Number(trim(env.RATE_LIMIT_GUEST_PER_HOUR)) || 5,
```

y después del bloque `revenuecat`:

```js
  // Modo invitado de la beta. Apagado, POST /auth/guest responde 404.
  guestMode: {
    enabled: trim(env.GUEST_MODE_ENABLED) === 'true',
  },
```

- [ ] **Step 3: Textos en inglés**

En `messages.js`, en `CODE_MESSAGES.en`, después de `UNAUTHORIZED: 'Please sign in again.',`:

```js
    GUEST_MODE_DISABLED: 'Guest mode is not available.',
    GUEST_EXPIRED: 'Your guest account expired. Create an account to keep using NutriLife.',
    GUEST_NOT_ALLOWED: 'Create an account to do this.',
```

- [ ] **Step 4: Tests del backend**

Run: `cd backend && npm test`
Expected: todo PASS (todavía nadie usa los códigos nuevos).

- [ ] **Step 5: Commit**

```bash
git add backend/src/database/backups/update_18_10_2026_guest_mode.sql backend/src/config/env_config.js backend/src/i18n/messages.js
git commit -m "feat(backend): columna, interruptor y textos del modo invitado"
```

---

### Task 2: Datos de ejemplo del invitado

**Files:**
- Create: `backend/src/modules/auth/guest.sampleData.js`
- Test: `backend/test/auth/guest.sampleData.test.js`

**Interfaces:**
- Produces:
  - `GUEST_TTL_MS: number` (24 h en ms)
  - `GUEST_PROFILE: { age: 28, goal: 'lose', height: 170 }`
  - `buildGuestSampleData(todayKey: 'YYYY-MM-DD', foodIds: number[]) → { physical: {day, height, weight}[], water: {day, glasses}[], meals: {day, items: {mealType, foodId, quantity}[]}[] }`

- [ ] **Step 1: Test que falla**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { buildGuestSampleData, GUEST_PROFILE, GUEST_TTL_MS } = await import(src('modules/auth/guest.sampleData.js'));

test('la cuenta dura 24 horas', () => {
  assert.equal(GUEST_TTL_MS, 24 * 60 * 60 * 1000);
});

test('agua de los últimos 7 días, de hace 6 días a hoy, dentro de 1..4 vasos', () => {
  const { water } = buildGuestSampleData('2026-10-18', [1]);
  assert.equal(water.length, 7);
  assert.equal(water[0].day, '2026-10-12');
  assert.equal(water[6].day, '2026-10-18');
  assert.ok(water.every(({ glasses }) => glasses >= 1 && glasses <= 4));
});

test('tres registros de peso con la altura del perfil, el último hoy', () => {
  const { physical } = buildGuestSampleData('2026-10-18', [1]);
  assert.deepEqual(physical.map((p) => p.day), ['2026-10-12', '2026-10-15', '2026-10-18']);
  assert.ok(physical.every((p) => p.height === GUEST_PROFILE.height));
  assert.ok(physical[0].weight > physical[2].weight);
});

test('desayuno, almuerzo y cena cada día, rotando los alimentos', () => {
  const { meals } = buildGuestSampleData('2026-10-18', [10, 20]);
  assert.equal(meals.length, 7);
  assert.deepEqual(meals[0].items.map((i) => i.mealType), ['BREAKFAST', 'LUNCH', 'DINNER']);
  assert.deepEqual(meals[0].items.map((i) => i.foodId), [10, 20, 10]);
  assert.deepEqual(meals[1].items.map((i) => i.foodId), [20, 10, 20]);
  assert.ok(meals.flatMap((m) => m.items).every((i) => i.quantity === 1));
});

test('sin alimentos en el catálogo no hay comidas', () => {
  assert.deepEqual(buildGuestSampleData('2026-10-18', []).meals, []);
});

test('cruza el fin de mes', () => {
  const { water } = buildGuestSampleData('2026-11-02', [1]);
  assert.equal(water[0].day, '2026-10-27');
});
```

- [ ] **Step 2: Correrlo**

Run: `cd backend && node --test test/auth/guest.sampleData.test.js`
Expected: FAIL (no existe el módulo).

- [ ] **Step 3: Implementación**

```js
// Perfil y datos de ejemplo de la cuenta de invitado: una semana de comidas,
// agua y peso para que el inicio y el progreso no salgan vacíos.

export const GUEST_TTL_MS = 24 * 60 * 60 * 1000;

export const GUEST_PROFILE = { age: 28, goal: 'lose', height: 170 };

const MEAL_TYPES = ['BREAKFAST', 'LUNCH', 'DINNER'];
// De hace 6 días a hoy. water_intake acepta de 1 a 4 vasos (la meta es 4).
const WATER_GLASSES = [4, 3, 4, 2, 4, 3, 1];
// Hace 6, 3 y 0 días: baja un poco, como pide el objetivo.
const WEIGHT_DAYS_AGO = [6, 3, 0];
const WEIGHTS = [72.4, 72.1, 71.8];

const shiftDay = (dayKey, days) => {
  const date = new Date(`${dayKey}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

/**
 * @param {string} todayKey Día de hoy 'YYYY-MM-DD' (hora de Bogotá).
 * @param {number[]} foodIds Alimentos del catálogo común para las comidas.
 */
export const buildGuestSampleData = (todayKey, foodIds) => {
  const days = [6, 5, 4, 3, 2, 1, 0].map((daysAgo) => shiftDay(todayKey, -daysAgo));

  return {
    physical: WEIGHT_DAYS_AGO.map((daysAgo, i) => ({
      day: shiftDay(todayKey, -daysAgo),
      height: GUEST_PROFILE.height,
      weight: WEIGHTS[i],
    })),
    water: days.map((day, i) => ({ day, glasses: WATER_GLASSES[i] })),
    meals:
      foodIds.length === 0
        ? []
        : days.map((day, d) => ({
            day,
            items: MEAL_TYPES.map((mealType, m) => ({
              mealType,
              foodId: foodIds[(d * MEAL_TYPES.length + m) % foodIds.length],
              quantity: 1,
            })),
          })),
  };
};
```

- [ ] **Step 4: Correrlo**

Run: `cd backend && node --test test/auth/guest.sampleData.test.js`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add backend/src/modules/auth/guest.sampleData.js backend/test/auth/guest.sampleData.test.js
git commit -m "feat(backend): datos de ejemplo de la cuenta de invitado"
```

---

### Task 3: `POST /auth/guest` y sesión de invitado

**Files:**
- Create: `backend/src/modules/auth/guest.repository.js`
- Modify: `backend/src/modules/auth/auth.repository.js` (`userSelect`)
- Modify: `backend/src/modules/auth/auth.service.js`
- Modify: `backend/src/modules/auth/auth.controller.js`
- Modify: `backend/src/modules/auth/auth.routes.js`
- Modify: `backend/src/middleware/rateLimit.middleware.js`
- Modify: `backend/test/auth/auth.service.test.js` (solo el mock nuevo)
- Test: `backend/test/auth/guest.service.test.js`, `backend/test/i18n/guestRateLimit.test.js`

**Interfaces:**
- Consumes: `buildGuestSampleData`, `GUEST_PROFILE`, `GUEST_TTL_MS` (Task 2); `config.guestMode.enabled`, `config.rateLimit.guestPerHour` (Task 1); `bogotaDayKey()` de `src/utils/bogotaDay.js`.
- Produces:
  - `guest.repository.js`: `findSampleFoodIds(limit = 6) → Promise<number[]>`, `createGuestAccount({ user, expiresAt, profile, sample }) → Promise<number>` (userId), `findExpiredGuestIds(limit = 100) → Promise<number[]>`.
  - `auth.service.js`: `loginAsGuest({ lang }) → Promise<{ token, user, needsProfileSetup, guestExpiresAt }>`; `user` lleva `isGuest: true` y `guestExpiresAt`. El JWT lleva `isGuest: true` y vence en `guestExpiresAt`. `getAuthModuleStatus()` agrega `guestModeEnabled: boolean`.
  - `rateLimit.middleware.js`: `guestRateLimit` (5/h por IP); `buildMiddleware` acepta `duration` (segundos, default 60).
  - Ruta `POST /api/v1/auth/guest` → 201 con `{ success, message, data: { token, user, needsProfileSetup, guestExpiresAt } }`.

- [ ] **Step 1: Repositorio del invitado**

`backend/src/modules/auth/guest.repository.js`:

```js
import pool from '../../database/connection.js';
import { createUser } from './auth.repository.js';

/** Alimentos del catálogo común para las comidas de ejemplo. */
export const findSampleFoodIds = async (limit = 6) => {
  const { rows } = await pool.query(
    `SELECT food_id AS "foodId"
     FROM foods
     WHERE is_global = TRUE AND is_active = TRUE
     ORDER BY food_id
     LIMIT $1`,
    [limit]
  );
  return rows.map((row) => row.foodId);
};

/**
 * Crea al invitado con su perfil y sus datos de ejemplo. Todo o nada: un
 * invitado a medias dejaría el inicio roto.
 * @returns {Promise<number>} userId
 */
export const createGuestAccount = async ({ user, expiresAt, profile, sample }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const { userId } = await createUser(user, client);

    await client.query(
      'UPDATE users SET guest_expires_at = $2, age = $3 WHERE user_id = $1',
      [userId, expiresAt, profile.age]
    );

    for (const { day, height, weight } of sample.physical) {
      await client.query(
        'INSERT INTO physical_records (user_id, height, weight, record_date) VALUES ($1, $2, $3, $4)',
        [userId, height, weight, day]
      );
    }

    for (const { day, glasses } of sample.water) {
      await client.query(
        'INSERT INTO water_intake (user_id, day, glasses) VALUES ($1, $2, $3)',
        [userId, day, glasses]
      );
    }

    for (const { day, items } of sample.meals) {
      const { rows } = await client.query(
        'INSERT INTO meal_records (user_id, record_date) VALUES ($1, $2) RETURNING meal_record_id AS "mealRecordId"',
        [userId, day]
      );
      for (const { foodId, quantity, mealType } of items) {
        await client.query(
          'INSERT INTO meal_record_details (meal_record_id, food_id, quantity, meal_type) VALUES ($1, $2, $3, $4)',
          [rows[0].mealRecordId, foodId, quantity, mealType]
        );
      }
    }

    await client.query('COMMIT');
    return userId;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/** Invitados vencidos, el más viejo primero. */
export const findExpiredGuestIds = async (limit = 100) => {
  const { rows } = await pool.query(
    `SELECT user_id AS "userId"
     FROM users
     WHERE guest_expires_at IS NOT NULL AND guest_expires_at <= NOW()
     ORDER BY guest_expires_at
     LIMIT $1`,
    [limit]
  );
  return rows.map((row) => row.userId);
};
```

- [ ] **Step 2: `guestExpiresAt` en el usuario del login**

En `auth.repository.js`, en `userSelect`, después de `u.pro_until AS "proUntil",`:

```sql
    u.guest_expires_at AS "guestExpiresAt",
```

- [ ] **Step 3: Test del service que falla**

`backend/test/auth/guest.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = [
  'createUser',
  'createUserWithProvider',
  'findProviderLink',
  'findUserByEmail',
  'findUserByProvider',
  'getAuthRepositoryStatus',
  'getDefaultRoleAndPlanIds',
  'linkAuthProvider',
  'markEmailVerified',
  'setPasswordAndVerify',
];

const repo = {};
const guestRepo = {};
const events = [];
const fridges = [];

mock.module(src('modules/auth/auth.repository.js'), {
  exports: Object.fromEntries(REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])),
});
mock.module(src('modules/auth/guest.repository.js'), {
  exports: {
    findSampleFoodIds: (...args) => guestRepo.findSampleFoodIds(...args),
    createGuestAccount: (...args) => guestRepo.createGuestAccount(...args),
    findExpiredGuestIds: async () => [],
  },
});
mock.module(src('modules/fridge/fridge.service.js'), {
  exports: { createFridgeService: async (userId) => { fridges.push(userId); } },
});
mock.module(src('modules/events/events.service.js'), {
  exports: { logEventService: async (event) => { events.push(event); } },
});
mock.module(src('modules/auth/google.verifier.js'), {
  exports: { verifyGoogleIdToken: async () => null },
});
mock.module(src('modules/auth/email-code.service.js'), {
  exports: {
    CODE_PURPOSE: { VERIFY_EMAIL: 'verify_email', RESET_PASSWORD: 'reset_password' },
    sendCode: async () => {},
    consumeCode: async () => {},
  },
});

const { config } = await import(src('config/env_config.js'));
const { loginAsGuest, getAuthModuleStatus } = await import(src('modules/auth/auth.service.js'));

let created;

beforeEach(() => {
  config.jwt.secret = 'test-secret';
  config.guestMode.enabled = true;
  events.length = 0;
  fridges.length = 0;
  created = null;
  repo.getDefaultRoleAndPlanIds = async () => ({ roleId: 2, planId: 1 });
  guestRepo.findSampleFoodIds = async () => [5, 6];
  guestRepo.createGuestAccount = async (input) => {
    created = input;
    return 41;
  };
  repo.findUserByEmail = async (email) => ({
    userId: 41,
    name: created.user.name,
    email,
    passwordHash: null,
    goal: 'lose',
    age: 28,
    emailVerifiedAt: created.user.emailVerifiedAt,
    role: 'USER',
    plan: 'FREE',
    guestExpiresAt: created.expiresAt,
  });
});

test('con el modo apagado responde 404', async () => {
  config.guestMode.enabled = false;
  await assert.rejects(loginAsGuest({ lang: 'es' }), { statusCode: 404, code: 'GUEST_MODE_DISABLED' });
});

test('crea un invitado FREE, verificado, sin contraseña y que vence en 24 h', async () => {
  const before = Date.now();
  const session = await loginAsGuest({ lang: 'es' });

  assert.equal(created.user.name, 'Invitado');
  assert.match(created.user.email, /^guest-[0-9a-f-]{36}@guest\.nutrilife\.invalid$/);
  assert.equal(created.user.passwordHash, null);
  assert.equal(created.user.roleId, 2);
  assert.equal(created.user.planId, 1);
  assert.ok(created.user.emailVerifiedAt instanceof Date);
  const ttl = created.expiresAt.getTime() - before;
  assert.ok(ttl >= 24 * 60 * 60 * 1000 - 1000 && ttl <= 24 * 60 * 60 * 1000 + 1000);
  assert.equal(created.sample.meals.length, 7);
  assert.equal(created.profile.age, 28);

  assert.equal(session.user.isGuest, true);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.needsProfileSetup, false);
  assert.equal(session.guestExpiresAt, created.expiresAt);
  assert.deepEqual(fridges, [41]);
  assert.ok(events.some((e) => e.eventType === 'REGISTER' && e.metadata.method === 'guest'));
});

test('en inglés se llama Guest', async () => {
  await loginAsGuest({ lang: 'en' });
  assert.equal(created.user.name, 'Guest');
});

test('el token es de invitado y vence con la cuenta', async () => {
  const session = await loginAsGuest({ lang: 'es' });
  const payload = jwt.verify(session.token, 'test-secret');
  assert.equal(payload.isGuest, true);
  assert.ok(Math.abs(payload.exp - Math.floor(created.expiresAt.getTime() / 1000)) <= 2);
});

test('el health dice si el modo invitado está encendido', async () => {
  assert.equal((await getAuthModuleStatus()).guestModeEnabled, true);
  config.guestMode.enabled = false;
  assert.equal((await getAuthModuleStatus()).guestModeEnabled, false);
});
```

Y en `backend/test/auth/auth.service.test.js`, junto a los demás `mock.module` (antes del `await import` del service), agregar:

```js
mock.module(src('modules/auth/guest.repository.js'), {
  exports: { findSampleFoodIds: async () => [], createGuestAccount: async () => 0, findExpiredGuestIds: async () => [] },
});
```

- [ ] **Step 4: Correrlo**

Run: `cd backend && node --experimental-test-module-mocks --test test/auth/guest.service.test.js`
Expected: FAIL (`loginAsGuest` no existe).

- [ ] **Step 5: Implementación en el service**

En `auth.service.js`:

Imports nuevos (junto a los existentes):

```js
import { randomUUID } from 'node:crypto';
import { createGuestAccount, findSampleFoodIds } from './guest.repository.js';
import { GUEST_PROFILE, GUEST_TTL_MS, buildGuestSampleData } from './guest.sampleData.js';
import { bogotaDayKey } from '../../utils/bogotaDay.js';
```

Constantes, después de `const UNIQUE_VIOLATION = '23505';`:

```js
const GUEST_EMAIL_DOMAIN = 'guest.nutrilife.invalid';
const GUEST_NAMES = { es: 'Invitado', en: 'Guest' };
```

En `getAuthModuleStatus`, el objeto que devuelve:

```js
    return {
      module: 'auth',
      status: 'running',
      repository,
      guestModeEnabled: config.guestMode.enabled,
    };
```

Reemplazar `issueToken` y `buildSession`:

```js
// El invitado no tiene contraseña para volver a entrar: su token dura lo que
// dura la cuenta, y al vencer el middleware responde GUEST_EXPIRED.
const tokenExpiry = (user) =>
  user.guestExpiresAt
    ? Math.max(1, Math.floor((new Date(user.guestExpiresAt).getTime() - Date.now()) / 1000))
    : JWT_EXPIRES_IN;

const issueToken = (user) => {
  if (!config.jwt.secret) {
    throw new AppError('JWT secret is not configured', 500, 'AUTH_CONFIG_ERROR');
  }

  const tokenPayload = {
    userId: user.userId,
    email: user.email,
    role: user.role,
    plan: user.plan,
    name: user.name,
    goal: user.goal,
    ...(user.guestExpiresAt ? { isGuest: true } : {}),
  };

  return jwt.sign(tokenPayload, config.jwt.secret, { expiresIn: tokenExpiry(user) });
};

// Respuesta común de los logins. Sin edad, el usuario no terminó el setup
// del perfil y la app lo manda ahí en vez de al Dashboard. Las cuentas
// normales no llevan `guestExpiresAt` ni `isGuest`.
const buildSession = (user) => {
  const { passwordHash, guestExpiresAt, ...safeUser } = user;

  return {
    token: issueToken(user),
    user: guestExpiresAt ? { ...safeUser, isGuest: true, guestExpiresAt } : safeUser,
    needsProfileSetup: user.age == null,
  };
};
```

Al final del archivo:

```js
// Cuenta de invitado de la beta: real, FREE, con datos de ejemplo y que se
// borra a las 24 h (guestCleanup.job.js).
export const loginAsGuest = async ({ lang } = {}) => {
  try {
    if (!config.guestMode.enabled) {
      throw new AppError('El modo invitado no está disponible.', 404, 'GUEST_MODE_DISABLED');
    }

    const defaults = await getDefaultRoleAndPlanIds();
    if (!defaults?.roleId || !defaults?.planId) {
      throw new AppError('Default role or plan is not configured', 500, 'AUTH_DEFAULTS_NOT_FOUND');
    }

    const email = `guest-${randomUUID()}@${GUEST_EMAIL_DOMAIN}`;
    const expiresAt = new Date(Date.now() + GUEST_TTL_MS);
    const sample = buildGuestSampleData(bogotaDayKey(), await findSampleFoodIds());

    const userId = await createGuestAccount({
      user: {
        name: GUEST_NAMES[lang] ?? GUEST_NAMES.es,
        email,
        passwordHash: null,
        goal: GUEST_PROFILE.goal,
        roleId: Number(defaults.roleId),
        planId: Number(defaults.planId),
        emailVerifiedAt: new Date(),
      },
      expiresAt,
      profile: GUEST_PROFILE,
      sample,
    });
    await createFridgeService(userId);

    await logEventService({
      eventType: 'REGISTER',
      category: 'AUTH',
      userId,
      metadata: { method: 'guest' },
    });

    // Se relee para tener rol, plan y edad con el mismo formato que el login.
    const user = await findUserByEmail(email);
    return { ...(await startSession(user)), guestExpiresAt: user.guestExpiresAt };
  } catch (error) {
    throw toAuthError(error);
  }
};
```

- [ ] **Step 6: Correr los tests del service**

Run: `cd backend && node --experimental-test-module-mocks --test test/auth/guest.service.test.js test/auth/auth.service.test.js`
Expected: PASS. Si algún test viejo de `auth.service.test.js` compara el usuario completo de la sesión, sigue pasando: las cuentas normales no ganan campos. Que una sesión normal no lleve `isGuest` ya lo cubren esos tests viejos.

- [ ] **Step 7: Rate limit con duración y test que falla**

`backend/test/i18n/guestRateLimit.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const created = [];
mock.module(src('config/redis.client.js'), {
  namedExports: { getRedisClient: async () => ({}) },
});
mock.module('rate-limiter-flexible', {
  namedExports: {
    RateLimiterRedis: class {
      constructor(opts) {
        created.push(opts);
      }
      async consume() {
        return { remainingPoints: 4, msBeforeNext: 1000 };
      }
    },
  },
});

const { guestRateLimit, chatRateLimit } = await import(src('middleware/rateLimit.middleware.js'));

const res = { setHeader() {} };

test('el invitado se limita a 5 por hora por IP', async () => {
  await guestRateLimit({ ip: '1.1.1.1' }, res, () => {});
  const opts = created.at(-1);
  assert.equal(opts.points, 5);
  assert.equal(opts.duration, 3600);
  assert.equal(opts.keyPrefix, 'rl:auth-guest');
});

test('los demás límites siguen siendo por minuto', async () => {
  await chatRateLimit({ ip: '1.1.1.1', user: { userId: 1 } }, res, () => {});
  assert.equal(created.at(-1).duration, 60);
});
```

Run: `cd backend && node --experimental-test-module-mocks --test test/i18n/guestRateLimit.test.js`
Expected: FAIL (`guestRateLimit` no existe).

- [ ] **Step 8: Implementación del rate limit**

En `rateLimit.middleware.js`, cambiar la firma de `buildMiddleware` y el `duration` del limitador:

```js
const buildMiddleware = ({ points, keyPrefix, keyExtractor, duration = 60 }) => {
```

```js
      const rateLimiter = new RateLimiterRedis({
        storeClient: redis,
        keyPrefix,
        points,
        duration,
      });
```

Y al final:

```js
/**
 * Rate limit de POST /auth/guest: cada llamada crea una cuenta.
 * Default: 5 por hora por IP.
 */
export const guestRateLimit = buildMiddleware({
  points: config.rateLimit.guestPerHour,
  duration: 60 * 60,
  keyPrefix: 'rl:auth-guest',
  keyExtractor: (req) => `guest:ip:${req.ip}`,
});
```

Run: `cd backend && node --experimental-test-module-mocks --test test/i18n/guestRateLimit.test.js test/i18n/rateLimit.middleware.test.js`
Expected: PASS.

- [ ] **Step 9: Controller y ruta**

En `auth.controller.js`, agregar `loginAsGuest` al import de `./auth.service.js` y:

```js
export const guestLogin = async (req, res, next) => {
  try {
    const authData = await loginAsGuest({ lang: req.lang });
    return successResponse(res, authData, 'Guest session started', 201);
  } catch (error) {
    next(error);
  }
};
```

En `auth.routes.js`: agregar `guestLogin` al import del controller, `guestRateLimit` al import de `rateLimit.middleware.js`, y después de la ruta `/google/link`:

```js
/**
 * @swagger
 * /api/v1/auth/guest:
 *   post:
 *     summary: Crea una cuenta de invitado temporal (24 h) con datos de ejemplo
 *     tags: [Auth]
 *     responses:
 *       201:
 *         description: Sesión de invitado (token, user con isGuest y guestExpiresAt)
 *       404:
 *         description: El modo invitado está apagado (GUEST_MODE_DISABLED)
 *       429:
 *         description: Demasiadas cuentas de invitado desde esta IP
 */
router.post('/guest', guestRateLimit, guestLogin);
```

- [ ] **Step 10: Todos los tests del backend**

Run: `cd backend && npm test`
Expected: PASS, incluido `coverage.test.js` (los tres códigos nuevos tienen inglés desde Task 1). Si un test viejo (p. ej. `auth.controller.test.js`) compara el objeto completo del health con `deepEqual`, agregarle `guestModeEnabled: false` a lo esperado: es el campo nuevo, no un error.

- [ ] **Step 11: Commit**

```bash
git add backend/src/modules/auth/guest.repository.js backend/src/modules/auth/auth.repository.js backend/src/modules/auth/auth.service.js backend/src/modules/auth/auth.controller.js backend/src/modules/auth/auth.routes.js backend/src/middleware/rateLimit.middleware.js backend/test/auth/guest.service.test.js backend/test/auth/auth.service.test.js backend/test/i18n/guestRateLimit.test.js
git commit -m "feat(backend): POST /auth/guest crea una cuenta de invitado de 24 h"
```

---

### Task 4: Bloqueos del invitado en el middleware

**Files:**
- Modify: `backend/src/middleware/auth.middleware.js`
- Modify: `backend/src/modules/user/user.routes.js` (ruta `POST /password`)
- Modify: `backend/src/modules/subscription/subscription.routes.js` (ruta `POST /sync`)
- Test: `backend/test/auth/auth.middleware.test.js`

**Interfaces:**
- Consumes: el JWT con `isGuest: true` de Task 3.
- Produces: `authenticateToken` (default export, sin cambio de firma) responde `401 GUEST_EXPIRED` para un token de invitado vencido; named export `rejectGuests(req, res, next)` → `403 GUEST_NOT_ALLOWED` si `req.user.isGuest`.

- [ ] **Step 1: Test que falla**

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { config } = await import(src('config/env_config.js'));
const { default: authenticateToken, rejectGuests } = await import(src('middleware/auth.middleware.js'));

config.jwt.secret = 'test-secret';

const run = (middleware, req) =>
  new Promise((resolve) => middleware(req, {}, (error) => resolve({ error, req })));

const bearer = (payload) => ({
  headers: { authorization: `Bearer ${jwt.sign(payload, 'test-secret')}` },
});

const expired = Math.floor(Date.now() / 1000) - 60;

test('un invitado vencido recibe GUEST_EXPIRED', async () => {
  const { error } = await run(authenticateToken(), bearer({ userId: 1, isGuest: true, exp: expired }));
  assert.equal(error.statusCode, 401);
  assert.equal(error.code, 'GUEST_EXPIRED');
});

test('un usuario normal vencido sigue recibiendo UNAUTHORIZED', async () => {
  const { error } = await run(authenticateToken(), bearer({ userId: 1, exp: expired }));
  assert.equal(error.statusCode, 401);
  assert.equal(error.code, 'UNAUTHORIZED');
});

test('un invitado vigente pasa y queda marcado', async () => {
  const { error, req } = await run(authenticateToken(), bearer({ userId: 1, role: 'USER', isGuest: true }));
  assert.equal(error, undefined);
  assert.equal(req.user.isGuest, true);
});

test('rejectGuests frena al invitado', async () => {
  const { error } = await run(rejectGuests, { user: { userId: 1, isGuest: true } });
  assert.equal(error.statusCode, 403);
  assert.equal(error.code, 'GUEST_NOT_ALLOWED');
});

test('rejectGuests deja pasar a los demás', async () => {
  const { error } = await run(rejectGuests, { user: { userId: 1 } });
  assert.equal(error, undefined);
});
```

- [ ] **Step 2: Correrlo**

Run: `cd backend && node --test test/auth/auth.middleware.test.js`
Expected: FAIL (`rejectGuests` no existe; el vencido da `UNAUTHORIZED`).

- [ ] **Step 3: Implementación**

`auth.middleware.js` completo (mantiene el estilo sin punto y coma):

```js
import jwt from "jsonwebtoken"
import { config } from "../config/env_config.js"
import { AppError } from "../utils/AppError.js"

// El token de un invitado vence con su cuenta: la app avisa en vez de solo
// mandar al login.
const isExpiredGuestToken = (err, token) =>
    err.name === 'TokenExpiredError' && jwt.decode(token)?.isGuest === true

function authenticateToken(requireRoles = []) {
    return (req, res, next) => {
        const authHeader = req.headers.authorization
        const token = authHeader?.split(" ")[1]
        if (!token) {
            return next(new AppError("No token provided", 401, 'UNAUTHORIZED', ['No token provided']))
        }
        jwt.verify(token, config.jwt.secret, (err, user) => {
            if (err) {
                if (isExpiredGuestToken(err, token)) {
                    return next(new AppError('Tu cuenta de invitado venció. Crea una cuenta para seguir usando NutriLife.', 401, 'GUEST_EXPIRED'))
                }
                return next(new AppError("Invalid token", 401, 'UNAUTHORIZED', ['Invalid token']))
            }
            if (requireRoles.length > 0 && !requireRoles.includes(user.role)) {
                return next(new AppError("Unauthorized role", 403, 'FORBIDDEN', ["Unauthorized role"]))
            }
            req.user = user
            next()
        })
    }
}

// Va después de authenticateToken en lo que un invitado no puede hacer:
// comprar o crear una contraseña.
export function rejectGuests(req, res, next) {
    if (req.user?.isGuest) {
        return next(new AppError('Crea una cuenta para hacer esto.', 403, 'GUEST_NOT_ALLOWED'))
    }
    next()
}

export default authenticateToken
```

- [ ] **Step 4: Aplicarlo en las rutas**

`user.routes.js`: cambiar el import a `import authenticateToken, { rejectGuests } from '../../middleware/auth.middleware.js';` y la ruta:

```js
router.post('/password', authenticateToken(), rejectGuests, validateSetPasswordRequest, setPassword);
```

`subscription.routes.js`: mismo cambio de import y:

```js
router.post('/sync', authenticateToken(['USER', 'ADMIN']), rejectGuests, subscriptionSyncRateLimit, syncSubscription);
```

- [ ] **Step 5: Correr todo**

Run: `cd backend && npm test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/src/middleware/auth.middleware.js backend/src/modules/user/user.routes.js backend/src/modules/subscription/subscription.routes.js backend/test/auth/auth.middleware.test.js
git commit -m "feat(backend): el invitado vencido recibe GUEST_EXPIRED y no puede comprar"
```

---

### Task 5: Job que borra a los invitados vencidos

**Files:**
- Create: `backend/src/modules/auth/guestCleanup.job.js`
- Modify: `backend/src/server.js`
- Test: `backend/test/auth/guestCleanup.job.test.js`

**Interfaces:**
- Consumes: `findExpiredGuestIds()` (Task 3), `deleteUserAccountData(userId) → Promise<boolean>` de `src/modules/user/user.repository.js`.
- Produces: `runGuestCleanup(findExpired?, deleteAccount?) → Promise<number[]>` (ids borrados; nunca lanza), `startGuestCleanupJob() → Timeout`.

- [ ] **Step 1: Test que falla**

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// El job importa los repositorios (y con ellos la base): se reemplazan.
mock.module(src('modules/auth/guest.repository.js'), {
  exports: { findExpiredGuestIds: async () => [], findSampleFoodIds: async () => [], createGuestAccount: async () => 0 },
});
mock.module(src('modules/user/user.repository.js'), {
  exports: { deleteUserAccountData: async () => true },
});

const { runGuestCleanup } = await import(src('modules/auth/guestCleanup.job.js'));

const quiet = async (fn) => {
  const { error, info } = console;
  console.error = () => {};
  console.info = () => {};
  try {
    return await fn();
  } finally {
    console.error = error;
    console.info = info;
  }
};

test('borra a cada invitado vencido', async () => {
  const deleted = [];
  const result = await quiet(() =>
    runGuestCleanup(async () => [3, 8], async (id) => {
      deleted.push(id);
      return true;
    })
  );
  assert.deepEqual(deleted, [3, 8]);
  assert.deepEqual(result, [3, 8]);
});

test('si uno falla, sigue con los demás', async () => {
  const result = await quiet(() =>
    runGuestCleanup(async () => [3, 8], async (id) => {
      if (id === 3) throw new Error('db caída');
      return true;
    })
  );
  assert.deepEqual(result, [8]);
});

test('no cuenta a quien ya no existía', async () => {
  const result = await quiet(() => runGuestCleanup(async () => [3], async () => false));
  assert.deepEqual(result, []);
});

test('un fallo al buscar no lanza', async () => {
  const result = await quiet(() =>
    runGuestCleanup(async () => {
      throw new Error('db caída');
    }, async () => true)
  );
  assert.deepEqual(result, []);
});
```

- [ ] **Step 2: Correrlo**

Run: `cd backend && node --experimental-test-module-mocks --test test/auth/guestCleanup.job.test.js`
Expected: FAIL (no existe el job).

- [ ] **Step 3: Implementación**

`backend/src/modules/auth/guestCleanup.job.js`:

```js
import { findExpiredGuestIds } from './guest.repository.js';
import { deleteUserAccountData } from '../user/user.repository.js';

// Cada cuánto se borran los invitados vencidos. Su token ya no sirve desde
// que vencen, así que esto solo limpia la base.
const INTERVAL_MS = 60 * 60 * 1000;

/** Un barrido. Nunca lanza: un fallo solo se registra y el resto sigue. */
export const runGuestCleanup = async (
  findExpired = findExpiredGuestIds,
  deleteAccount = deleteUserAccountData
) => {
  let userIds;
  try {
    userIds = await findExpired();
  } catch (error) {
    console.error('[guestCleanup] no se pudieron buscar los invitados vencidos:', error.message);
    return [];
  }

  const deleted = [];
  for (const userId of userIds) {
    try {
      if (await deleteAccount(userId)) deleted.push(userId);
    } catch (error) {
      console.error(`[guestCleanup] no se pudo borrar al invitado ${userId}:`, error.message);
    }
  }

  if (deleted.length > 0) {
    console.info(`[guestCleanup] ${deleted.length} invitado(s) borrado(s):`, deleted.join(', '));
  }
  return deleted;
};

/** Barre al arrancar y después cada hora. */
export const startGuestCleanupJob = () => {
  runGuestCleanup();
  const timer = setInterval(runGuestCleanup, INTERVAL_MS);
  timer.unref?.();
  return timer;
};
```

En `server.js`: `import { startGuestCleanupJob } from './modules/auth/guestCleanup.job.js';` y, después de `startProExpiryJob();`:

```js
      startGuestCleanupJob();
```

- [ ] **Step 4: Correr todo**

Run: `cd backend && npm test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/modules/auth/guestCleanup.job.js backend/src/server.js backend/test/auth/guestCleanup.job.test.js
git commit -m "feat(backend): job que borra a los invitados vencidos cada hora"
```

---

### Task 6: Invitados en el panel

**Files:**
- Modify: `backend/src/modules/admin/admin.repository.js` (`authMethodSql`, `usersQuery`, CTE `reg` de `seriesQuery`, `recentUsersQuery`)
- Modify: `admin-panel/src/types/admin.ts:6`
- Modify: `admin-panel/src/components/CategoryBadge.tsx:55-69`

**Interfaces:**
- Produces: `authMethod` puede valer `'GUEST'` en la lista y el detalle de usuarios. El overview no cuenta invitados.

- [ ] **Step 1: Backend**

`authMethodSql` (el invitado tampoco tiene contraseña: va antes que GOOGLE):

```js
const authMethodSql = (alias) => `
  CASE
    WHEN ${alias}.guest_expires_at IS NOT NULL THEN 'GUEST'
    WHEN ${alias}.password IS NULL THEN 'GOOGLE'
    WHEN EXISTS (
      SELECT 1 FROM user_auth_providers ap WHERE ap.user_id = ${alias}.user_id
    ) THEN 'BOTH'
    ELSE 'EMAIL'
  END`;
```

En `getOverview`, comentario sobre la constante `usersQuery`: `// Los invitados de la beta no cuentan como usuarios.` y agregar al final de `usersQuery` (después de los `INNER JOIN`):

```sql
    WHERE u.guest_expires_at IS NULL
```

En el CTE `reg` de `seriesQuery`:

```sql
      WHERE u.created_at >= NOW() - (($1::int + 1) * INTERVAL '1 day')
        AND u.guest_expires_at IS NULL
```

En `recentUsersQuery`, antes del `ORDER BY`:

```sql
    WHERE u.guest_expires_at IS NULL
```

- [ ] **Step 2: Panel**

`admin.ts`: `export type AuthMethod = 'EMAIL' | 'GOOGLE' | 'BOTH' | 'GUEST';`

`CategoryBadge.tsx`:

```tsx
const AUTH_METHOD_LABEL: Record<string, string> = {
  EMAIL: 'Email',
  GOOGLE: 'Google',
  BOTH: 'Ambos',
  GUEST: 'Invitado',
};

/** Cómo inicia sesión el usuario: Email, Google, Ambos o Invitado. */
export function authMethodLabel(method: string) {
  return AUTH_METHOD_LABEL[method] ?? method;
}

const AUTH_METHOD_VARIANT = { EMAIL: 'outline', GUEST: 'warning' } as const;

export function AuthMethodBadge({ method }: { method: string }) {
  const variant = AUTH_METHOD_VARIANT[method as keyof typeof AUTH_METHOD_VARIANT] ?? 'info';
  return <Badge variant={variant}>{authMethodLabel(method)}</Badge>;
}
```

- [ ] **Step 3: Verificar**

Run: `cd backend && npm test`
Expected: PASS.

Run: `cd admin-panel && npm run build`
Expected: build sin errores de TypeScript.

- [ ] **Step 4: Commit**

```bash
git add backend/src/modules/admin/admin.repository.js admin-panel/src/types/admin.ts admin-panel/src/components/CategoryBadge.tsx
git commit -m "feat(panel): los invitados no cuentan como usuarios y salen marcados"
```

---

### Task 7: App — repositorio y sesión de invitado

**Files:**
- Modify: `nutrilife/lib/core/network/api_routes.dart`
- Modify: `nutrilife/lib/features/auth/data/auth_repository.dart`
- Modify: `nutrilife/lib/core/services/session_service.dart`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb`
- Test: `nutrilife/test/features/auth/auth_repository_google_test.dart`, `nutrilife/test/core/services/session_service_test.dart`

**Interfaces:**
- Consumes: `POST /auth/guest` y `guestModeEnabled` de `GET /auth/health` (Task 3).
- Produces:
  - `ApiRoutes.authGuest = '/auth/guest'`
  - `AuthRepository.isGuestModeEnabled() → Future<bool>` (false ante cualquier fallo)
  - `AuthRepository.loginAsGuest() → Future<GoogleLoginResult>`
  - `SessionService.isGuest → bool`, `SessionService.guestExpiresAt → DateTime?` (hora local)
  - Clave ARB `authErrorGuest`.

- [ ] **Step 1: Textos**

En `app_es.arb`, después de `"authErrorGoogle"`:

```json
  "authErrorGuest": "No se pudo entrar como invitado. Inténtalo de nuevo.",
```

En `app_en.arb`, en el mismo lugar:

```json
  "authErrorGuest": "We couldn't sign you in as a guest. Please try again.",
```

Run: `cd nutrilife && flutter gen-l10n`

- [ ] **Step 2: Tests que fallan**

Al final del `main()` de `test/features/auth/auth_repository_google_test.dart`:

```dart
  group('modo invitado', () {
    test('el health con guestModeEnabled true lo enciende', () async {
      final adapter = _FakeAdapter(200, {
        'success': true,
        'data': {'module': 'auth', 'guestModeEnabled': true},
      });
      expect(await _repoWith(adapter).isGuestModeEnabled(), isTrue);
      expect(adapter.lastRequest!.path, ApiRoutes.authHealth);
    });

    test('sin la bandera está apagado', () async {
      final adapter = _FakeAdapter(200, {'success': true, 'data': {'module': 'auth'}});
      expect(await _repoWith(adapter).isGuestModeEnabled(), isFalse);
    });

    test('si el health falla está apagado', () async {
      final adapter = _FakeAdapter(500, {'success': false});
      expect(await _repoWith(adapter).isGuestModeEnabled(), isFalse);
    });

    test('loginAsGuest pide la sesión de invitado', () async {
      final adapter = _FakeAdapter(201, {
        'success': true,
        'data': {
          'token': 'jwt-guest',
          'user': {'userId': 41, 'name': 'Invitado', 'isGuest': true, 'guestExpiresAt': '2026-10-19T15:00:00.000Z'},
          'needsProfileSetup': false,
          'guestExpiresAt': '2026-10-19T15:00:00.000Z',
        },
      });
      final result = await _repoWith(adapter).loginAsGuest();
      expect(adapter.lastRequest!.path, ApiRoutes.authGuest);
      expect(adapter.lastRequest!.method, 'POST');
      expect(result.token, 'jwt-guest');
      expect(result.user['isGuest'], isTrue);
      expect(result.needsProfileSetup, isFalse);
    });

    test('si el backend lo apagó, se ve su mensaje', () async {
      final adapter = _FakeAdapter(404, {
        'success': false,
        'message': 'El modo invitado no está disponible.',
        'error': {'code': 'GUEST_MODE_DISABLED', 'details': []},
      });
      expect(
        () => _repoWith(adapter).loginAsGuest(),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'El modo invitado no está disponible.')),
      );
    });
  });
```

En `test/core/services/session_service_test.dart`, dentro de `main()`:

```dart
  test('un invitado no se ata a RevenueCat', () async {
    await SessionService.save(
      token: 'jwt-guest',
      user: {'userId': 41, 'isGuest': true, 'guestExpiresAt': '2026-10-19T15:00:00.000Z'},
    );

    expect(purchases.loggedIn, isEmpty);
    expect(SessionService.isGuest, isTrue);
    expect(SessionService.guestExpiresAt, DateTime.utc(2026, 10, 19, 15).toLocal());
  });

  test('una cuenta normal no es invitado', () async {
    await SessionService.save(token: 'jwt', user: {'userId': 8});

    expect(SessionService.isGuest, isFalse);
    expect(SessionService.guestExpiresAt, isNull);
  });

  test('restaurar la sesión recuerda que es invitado y clear lo olvida', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'jwt-guest',
      'auth_user': '{"userId":41,"isGuest":true,"guestExpiresAt":"2026-10-19T15:00:00.000Z"}',
    });

    await SessionService.restore();
    expect(SessionService.isGuest, isTrue);

    await SessionService.clear();
    expect(SessionService.isGuest, isFalse);
  });
```

- [ ] **Step 3: Correrlos**

Run: `cd nutrilife && flutter test test/features/auth/auth_repository_google_test.dart test/core/services/session_service_test.dart`
Expected: FAIL (no compilan: faltan `authGuest`, `isGuestModeEnabled`, `loginAsGuest`, `isGuest`).

- [ ] **Step 4: Implementación**

`api_routes.dart`, después de `authHealth`:

```dart
  static const String authGuest = '/auth/guest';
```

`auth_repository.dart`, después de `resetPassword`:

```dart
  /// true si el backend tiene el modo invitado encendido. Ante cualquier
  /// fallo, false: el botón no aparece y el login sigue como siempre.
  Future<bool> isGuestModeEnabled() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiRoutes.authHealth,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data?['data'];
      return data is Map && data['guestModeEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Crea una cuenta de invitado de 24 h y devuelve su sesión.
  Future<GoogleLoginResult> loginAsGuest() => _postSession(
    ApiRoutes.authGuest,
    const {},
    currentL10n.authErrorGuest,
  );
```

`session_service.dart`:

```dart
class SessionService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  static Map<String, dynamic>? _user;

  /// true si la sesión actual es de una cuenta de invitado de la beta.
  static bool get isGuest => _user?['isGuest'] == true;

  /// Hasta cuándo dura la cuenta de invitado, en hora local.
  static DateTime? get guestExpiresAt => DateTime.tryParse(
    _user?['guestExpiresAt']?.toString() ?? '',
  )?.toLocal();

  // Ata las compras de RevenueCat a la cuenta de NutriLife, no al teléfono.
  // El backend manda el id como `userId`; `id` queda por sesiones viejas.
  // El invitado no compra: no se ata.
  static Future<void> _linkPurchases(Map<String, dynamic> user) async {
    if (user['isGuest'] == true) return;
    final id = (user['userId'] ?? user['id'])?.toString().trim();
    if (id != null && id.isNotEmpty) await PurchaseService.instance.logIn(id);
  }
```

En `save`, después de `DioClient.authToken = token;`: `_user = user;` y en su `catch`, junto a `DioClient.authToken = null;`: `_user = null;`.

En `restore`, después de `DioClient.authToken = token;`: `_user = decodedUser;`.

En `clear`, después de `DioClient.authToken = null;`: `_user = null;`.

- [ ] **Step 5: Correrlos**

Run: `cd nutrilife && flutter test test/features/auth/auth_repository_google_test.dart test/core/services/session_service_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/core/network/api_routes.dart nutrilife/lib/features/auth/data/auth_repository.dart nutrilife/lib/core/services/session_service.dart nutrilife/lib/l10n/ nutrilife/test/features/auth/auth_repository_google_test.dart nutrilife/test/core/services/session_service_test.dart
git commit -m "feat(app): repositorio y sesión de la cuenta de invitado"
```

---

### Task 8: App — botón y alerta en el login

**Files:**
- Create: `nutrilife/lib/features/auth/presentation/widgets/guest_notice_dialog.dart`
- Create: `nutrilife/lib/features/auth/presentation/guest_sign_in_flow.dart`
- Modify: `nutrilife/lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `nutrilife/test/flutter_test_config.dart`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb`
- Test: `nutrilife/test/features/auth/guest_login_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.isGuestModeEnabled()`, `AuthRepository.loginAsGuest()`, `SessionService.save`, `openAppAfterLogin` (de `google_sign_in_flow.dart`).
- Produces:
  - `showGuestNoticeDialog(BuildContext) → Future<bool>`
  - `signInAsGuest(BuildContext, {AuthRepository? repository}) → Future<String?>` (mensaje de error o null)
  - `LoginScreen({Key? key, AuthRepository? authRepository, String? notice})` y `static Future<bool> Function() LoginScreen.guestModeCheck`
  - Claves ARB `authGuestButton`, `authGuestDialogTitle`, `authGuestDialogSample`, `authGuestDialogExpires`, `authGuestDialogFree`, `authGuestDialogCreateAccount`, `authGuestDialogConfirm`, `authGuestExpired`.

- [ ] **Step 1: Textos**

`app_es.arb`, después de `"authErrorGuest"`:

```json
  "authGuestButton": "Entrar como invitado",
  "authGuestDialogTitle": "Entrar como invitado",
  "authGuestDialogSample": "Es una cuenta de prueba con datos de ejemplo.",
  "authGuestDialogExpires": "Se borra en 24 horas, junto con todo lo que registres.",
  "authGuestDialogFree": "Tiene el plan FREE y no puedes comprar PRO.",
  "authGuestDialogCreateAccount": "Si quieres guardar tu progreso, crea una cuenta.",
  "authGuestDialogConfirm": "Entrar",
  "authGuestExpired": "Tu cuenta de invitado venció. Crea una cuenta para seguir.",
```

`app_en.arb`, mismo lugar:

```json
  "authGuestButton": "Continue as guest",
  "authGuestDialogTitle": "Continue as guest",
  "authGuestDialogSample": "This is a test account with sample data.",
  "authGuestDialogExpires": "It's deleted after 24 hours, along with everything you log.",
  "authGuestDialogFree": "It's on the FREE plan and you can't buy PRO.",
  "authGuestDialogCreateAccount": "To keep your progress, create an account.",
  "authGuestDialogConfirm": "Continue",
  "authGuestExpired": "Your guest account expired. Create an account to keep going.",
```

Run: `cd nutrilife && flutter gen-l10n`

- [ ] **Step 2: En los tests el botón no consulta la red**

`test/flutter_test_config.dart`: agregar el import `import 'package:nutrilife/features/auth/presentation/screens/login_screen.dart';` y dentro de `testExecutable`, antes de `setUp`:

```dart
  // El login pregunta al backend si hay modo invitado; en los tests, no, salvo
  // que el test pase su propio AuthRepository.
  LoginScreen.guestModeCheck = () async => false;
```

- [ ] **Step 3: Test que falla**

`test/features/auth/guest_login_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/core/services/session_service.dart';
import 'package:nutrilife/features/auth/data/auth_repository.dart';
import 'package:nutrilife/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.enabled = true, this.fails = false}) : super(dio: Dio());

  final bool enabled;
  final bool fails;
  int guestCalls = 0;

  @override
  Future<bool> isGuestModeEnabled() async => enabled;

  @override
  Future<GoogleLoginResult> loginAsGuest() async {
    guestCalls++;
    if (fails) throw const AuthException('El modo invitado no está disponible.');
    // needsProfileSetup: true abre el setup, más liviano que el Dashboard.
    return const GoogleLoginResult(
      token: 'jwt-guest',
      user: {'userId': 41, 'name': 'Invitado', 'isGuest': true},
      needsProfileSetup: true,
      offerPasswordSetup: false,
    );
  }
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  final originalPurchases = PurchaseService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PurchaseService.instance = FakePurchaseService();
  });

  tearDown(() async {
    await SessionService.clear();
    PurchaseService.instance = originalPurchases;
  });

  testWidgets('sin modo invitado no hay botón', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository(enabled: false))));
    await tester.pumpAndSettle();

    expect(find.text('Entrar como invitado'), findsNothing);
  });

  testWidgets('la alerta explica la cuenta y Cancelar no crea nada', (tester) async {
    _tallScreen(tester);
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('• Es una cuenta de prueba con datos de ejemplo.'), findsOneWidget);
    expect(find.text('• Se borra en 24 horas, junto con todo lo que registres.'), findsOneWidget);
    expect(find.text('• Tiene el plan FREE y no puedes comprar PRO.'), findsOneWidget);
    expect(find.text('• Si quieres guardar tu progreso, crea una cuenta.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.guestCalls, 0);
    expect(SessionService.isGuest, isFalse);
  });

  testWidgets('Entrar crea la sesión de invitado', (tester) async {
    _tallScreen(tester);
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repo.guestCalls, 1);
    expect(SessionService.isGuest, isTrue);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('si falla, el error sale en el login', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository(fails: true))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('El modo invitado no está disponible.'), findsOneWidget);
  });

  testWidgets('el aviso de invitado vencido sale al abrir el login', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(
      LoginScreen(
        authRepository: _FakeAuthRepository(enabled: false),
        notice: 'Tu cuenta de invitado venció. Crea una cuenta para seguir.',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta de invitado venció. Crea una cuenta para seguir.'), findsOneWidget);
  });

  testWidgets('el botón se ve en inglés', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(l10nApp(LoginScreen(authRepository: _FakeAuthRepository()), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
```

Run: `cd nutrilife && flutter test test/features/auth/guest_login_test.dart`
Expected: FAIL (no compila: `LoginScreen` no tiene `authRepository` ni `notice`).

- [ ] **Step 4: La alerta**

`lib/features/auth/presentation/widgets/guest_notice_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Explica la cuenta de invitado antes de crearla. true si eligió entrar.
Future<bool> showGuestNoticeDialog(BuildContext context) async {
  final l10n = context.l10n;
  final points = [
    l10n.authGuestDialogSample,
    l10n.authGuestDialogExpires,
    l10n.authGuestDialogFree,
    l10n.authGuestDialogCreateAccount,
  ];

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.authGuestDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $point'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.authGuestDialogConfirm),
        ),
      ],
    ),
  );
  return confirmed == true;
}
```

- [ ] **Step 5: El flujo**

`lib/features/auth/presentation/guest_sign_in_flow.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/session_service.dart';
import '../data/auth_repository.dart';
import 'google_sign_in_flow.dart';

/// Crea la cuenta de invitado y abre la app. Devuelve el mensaje de error a
/// mostrar, o null si salió bien.
Future<String?> signInAsGuest(
  BuildContext context, {
  AuthRepository? repository,
}) async {
  try {
    final result = await (repository ?? AuthRepository()).loginAsGuest();
    await SessionService.save(token: result.token, user: result.user);

    if (!context.mounted) return null;
    openAppAfterLogin(
      context,
      result.user,
      needsProfileSetup: result.needsProfileSetup,
    );
    return null;
  } on AuthException catch (error) {
    return error.message;
  } catch (_) {
    return currentL10n.authErrorGuest;
  }
}
```

- [ ] **Step 6: El login**

En `login_screen.dart`:

Imports nuevos:

```dart
import '../../data/auth_repository.dart';
import '../guest_sign_in_flow.dart';
import '../widgets/guest_notice_dialog.dart';
```

`LoginScreen`:

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.authRepository, this.notice});

  /// Solo para pruebas; por defecto usa el repositorio real.
  final AuthRepository? authRepository;

  /// Aviso que se muestra al abrir (p. ej. que venció la cuenta de invitado).
  final String? notice;

  /// Pregunta al backend si hay modo invitado. Los tests la reemplazan.
  static Future<bool> Function() guestModeCheck =
      () => AuthRepository().isGuestModeEnabled();
```

y en su `build`, `Flexible(child: _LoginPanel(isCompact: isCompact))` pasa a:

```dart
                            Flexible(
                              child: _LoginPanel(
                                isCompact: isCompact,
                                authRepository: authRepository,
                                notice: notice,
                              ),
                            ),
```

`_LoginPanel`:

```dart
class _LoginPanel extends StatefulWidget {
  const _LoginPanel({
    required this.isCompact,
    this.authRepository,
    this.notice,
  });

  final bool isCompact;
  final AuthRepository? authRepository;
  final String? notice;
```

En `_LoginPanelState`: el campo `bool _guestModeEnabled = false;` junto a `_isLoading`, y al final de `initState`:

```dart
    final check =
        widget.authRepository?.isGuestModeEnabled() ??
        LoginScreen.guestModeCheck();
    check.then((enabled) {
      if (enabled && mounted) setState(() => _guestModeEnabled = true);
    });

    final notice = widget.notice;
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notice)),
        );
      });
    }
```

Método nuevo, después de `_handleGoogleLogin`:

```dart
  Future<void> _handleGuestLogin() async {
    if (!await showGuestNoticeDialog(context) || !mounted) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Si sale bien, navega y este panel desaparece.
    final error = await signInAsGuest(context, repository: widget.authRepository);
    if (!mounted) return;
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });
  }
```

En `build`, después del `Text.rich` de los términos de Google (el último hijo de la `Column`):

```dart
                if (_guestModeEnabled) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleGuestLogin,
                      child: Text(
                        context.l10n.authGuestButton,
                        style: const TextStyle(
                          color: AppTheme.primaryStart,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
```

- [ ] **Step 7: Correr los tests**

Run: `cd nutrilife && flutter test test/features/auth/`
Expected: PASS (los nuevos y los viejos del login).

Si el test "Entrar crea la sesión de invitado" falla porque `ProfileSetupScreen` hace peticiones en `initState`, cambiar el fake a `needsProfileSetup: false` no sirve (el Dashboard pide más todavía): en su lugar, quitar la última expectativa (`find.byType(LoginScreen)`) y dejar las de `guestCalls` y `SessionService.isGuest`.

- [ ] **Step 8: Commit**

```bash
git add nutrilife/lib/features/auth/ nutrilife/lib/l10n/ nutrilife/test/flutter_test_config.dart nutrilife/test/features/auth/guest_login_test.dart
git commit -m "feat(app): botón Entrar como invitado con su alerta en el login"
```

---

### Task 9: App — franja de invitado y perfil

**Files:**
- Create: `nutrilife/lib/features/home/presentation/widgets/guest_banner.dart`
- Modify: `nutrilife/lib/features/home/presentation/screens/dashboard_screen.dart`
- Modify: `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart:339-341`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb`
- Test: `nutrilife/test/features/home/guest_banner_test.dart`, `nutrilife/test/features/profile/profile_l10n_test.dart`

**Interfaces:**
- Consumes: `SessionService.isGuest`, `SessionService.guestExpiresAt` (Task 7).
- Produces: `GuestBanner({required DateTime expiresAt, required VoidCallback onCreateAccount, DateTime Function()? now})`. Claves ARB `homeGuestBanner` (placeholder `hours`, int), `homeGuestBannerSoon`, `homeGuestCreateAccount`.

- [ ] **Step 1: Textos**

`app_es.arb`, después de `"authGuestExpired"`:

```json
  "homeGuestBanner": "Modo invitado · se borra en {hours} h",
  "@homeGuestBanner": {
    "placeholders": {
      "hours": {
        "type": "int"
      }
    }
  },
  "homeGuestBannerSoon": "Modo invitado · se borra en menos de 1 h",
  "homeGuestCreateAccount": "Crear cuenta",
```

`app_en.arb`:

```json
  "homeGuestBanner": "Guest mode · deleted in {hours} h",
  "@homeGuestBanner": {
    "placeholders": {
      "hours": {
        "type": "int"
      }
    }
  },
  "homeGuestBannerSoon": "Guest mode · deleted in under 1 h",
  "homeGuestCreateAccount": "Create account",
```

Run: `cd nutrilife && flutter gen-l10n`

- [ ] **Step 2: Test que falla**

`test/features/home/guest_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/home/presentation/widgets/guest_banner.dart';

import '../../helpers/l10n_app.dart';

final _now = DateTime(2026, 10, 18, 12);

Widget _banner({required Duration left, VoidCallback? onCreateAccount}) => l10nApp(
  Scaffold(
    body: GuestBanner(
      expiresAt: _now.add(left),
      now: () => _now,
      onCreateAccount: onCreateAccount ?? () {},
    ),
  ),
);

void main() {
  testWidgets('dice cuántas horas le quedan', (tester) async {
    await tester.pumpWidget(_banner(left: const Duration(hours: 23, minutes: 40)));

    expect(find.text('Modo invitado · se borra en 23 h'), findsOneWidget);
  });

  testWidgets('con menos de una hora lo dice', (tester) async {
    await tester.pumpWidget(_banner(left: const Duration(minutes: 20)));

    expect(find.text('Modo invitado · se borra en menos de 1 h'), findsOneWidget);
  });

  testWidgets('Crear cuenta llama al callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_banner(left: const Duration(hours: 5), onCreateAccount: () => taps++));

    await tester.tap(find.text('Crear cuenta'));
    expect(taps, 1);
  });

  testWidgets('en inglés cabe a 375 px', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(l10nApp(
      Scaffold(
        body: GuestBanner(expiresAt: _now.add(const Duration(hours: 23)), now: () => _now, onCreateAccount: () {}),
      ),
      locale: const Locale('en'),
    ));

    expect(find.text('Guest mode · deleted in 23 h'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

Run: `cd nutrilife && flutter test test/features/home/guest_banner_test.dart`
Expected: FAIL (no existe `GuestBanner`).

- [ ] **Step 3: La franja**

`lib/features/home/presentation/widgets/guest_banner.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Recuerda arriba del inicio que la cuenta es de invitado y cuándo se borra.
class GuestBanner extends StatelessWidget {
  const GuestBanner({
    super.key,
    required this.expiresAt,
    required this.onCreateAccount,
    this.now,
  });

  final DateTime expiresAt;
  final VoidCallback onCreateAccount;

  /// Solo para pruebas.
  final DateTime Function()? now;

  static const _ink = Color(0xFF8A5A00);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hoursLeft = expiresAt.difference((now ?? DateTime.now)()).inHours;
    final text = hoursLeft < 1
        ? l10n.homeGuestBannerSoon
        : l10n.homeGuestBanner(hoursLeft);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: _ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onCreateAccount,
            child: Text(
              l10n.homeGuestCreateAccount,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
```

Run: `cd nutrilife && flutter test test/features/home/guest_banner_test.dart`
Expected: PASS.

- [ ] **Step 4: En el Dashboard**

En `dashboard_screen.dart`, imports nuevos:

```dart
import '../../../auth/presentation/screens/register_screen.dart';
import '../widgets/guest_banner.dart';
```

En `build`, en la `Column` del `SafeArea`, después de `const HomeHeader(),`:

```dart
              if (SessionService.isGuest &&
                  SessionService.guestExpiresAt != null)
                GuestBanner(
                  expiresAt: SessionService.guestExpiresAt!,
                  onCreateAccount: _createAccountFromGuest,
                ),
```

Método nuevo, antes de `_buildProfileTab`:

```dart
  /// Sale del invitado y abre el registro encima del login. La cuenta de
  /// invitado se queda hasta que venza; sus datos no pasan a la nueva.
  Future<void> _createAccountFromGuest() async {
    await SessionService.clear();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    navigator.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }
```

- [ ] **Step 5: Perfil sin "Eliminar cuenta" para el invitado — test que falla**

En `test/features/profile/profile_l10n_test.dart`, agregar los imports `package:nutrilife/core/services/purchase_service.dart` y `package:nutrilife/core/services/session_service.dart` si faltan, y dentro de `group('ProfileScreen', ...)`:

```dart
    testWidgets('el invitado no ve Eliminar cuenta', (tester) async {
      _tallScreen(tester);
      final originalPurchases = PurchaseService.instance;
      PurchaseService.instance = FakePurchaseService();
      addTearDown(() async {
        await SessionService.clear();
        PurchaseService.instance = originalPurchases;
      });
      await SessionService.save(token: 'jwt-guest', user: {'userId': 41, 'isGuest': true});

      await tester.pumpWidget(_profileScreen(const Locale('es')));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Eliminar cuenta'), findsNothing);
    });
```

Run: `cd nutrilife && flutter test test/features/profile/profile_l10n_test.dart`
Expected: FAIL (todavía se ve "Eliminar cuenta").

- [ ] **Step 6: Implementación en el perfil**

En `profile_screen.dart` (importa `../../../../core/services/session_service.dart` si no lo hace), reemplazar:

```dart
                const SizedBox(height: 12),
                _DeleteAccountButton(onPressed: () => _deleteAccount(profile)),
```

por:

```dart
                // El invitado se borra solo a las 24 h y no tiene contraseña
                // ni Google para confirmar.
                if (!SessionService.isGuest) ...[
                  const SizedBox(height: 12),
                  _DeleteAccountButton(
                    onPressed: () => _deleteAccount(profile),
                  ),
                ],
```

Run: `cd nutrilife && flutter test test/features/profile/ test/features/home/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add nutrilife/lib/features/home/ nutrilife/lib/features/profile/presentation/screens/profile_screen.dart nutrilife/lib/l10n/ nutrilife/test/features/home/guest_banner_test.dart nutrilife/test/features/profile/profile_l10n_test.dart
git commit -m "feat(app): franja de invitado en el inicio y perfil sin eliminar cuenta"
```

---

### Task 10: App — Premium bloqueado y aviso de vencimiento

**Files:**
- Modify: `nutrilife/lib/features/premium/presentation/screens/premium_screen.dart`
- Modify: `nutrilife/lib/core/network/dio_client.dart`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb`
- Test: `nutrilife/test/features/premium/premium_screen_test.dart`, `nutrilife/test/core/network/dio_client_redirect_test.dart`

**Interfaces:**
- Consumes: `SessionService.isGuest` (Task 7), `LoginScreen(notice:)` y `authGuestExpired` (Task 8), código `GUEST_EXPIRED` (Task 4).
- Produces: `PremiumScreen({..., bool? isGuest})`; función `isGuestExpiredResponse(dynamic body) → bool` en `dio_client.dart`; clave ARB `premiumGuestBlocked`.

- [ ] **Step 1: Texto**

`app_es.arb`, después de `"homeGuestCreateAccount"`: `"premiumGuestBlocked": "Crea una cuenta para suscribirte.",`
`app_en.arb`: `"premiumGuestBlocked": "Create an account to subscribe.",`

Run: `cd nutrilife && flutter gen-l10n`

- [ ] **Step 2: Tests que fallan**

En `premium_screen_test.dart`, agregar a `_pump` el parámetro `bool isGuest = false` y pasarlo: `PremiumScreen(purchases: purchases, subscriptions: subscriptions ?? _FakeSubscriptions(), isGuest: isGuest)`. Luego, en `main()`:

```dart
  testWidgets('el invitado no puede comprar ni restaurar', (tester) async {
    final purchases = FakePurchaseService();
    await _pump(tester, purchases: purchases, isGuest: true);

    expect(find.text('Crea una cuenta para suscribirte.'), findsOneWidget);

    await tester.tap(find.text('Suscribirme'));
    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(purchases.purchased, isEmpty);
    expect(purchases.restoreCalls, 0);
  });
```

(`premiumSubscribe` = "Suscribirme" y `premiumRestore` = "Restaurar compras" en `app_es.arb`.)

En `dio_client_redirect_test.dart`, en `main()`:

```dart
  group('isGuestExpiredResponse', () {
    test('reconoce GUEST_EXPIRED', () {
      expect(
        isGuestExpiredResponse({
          'success': false,
          'error': {'code': 'GUEST_EXPIRED', 'details': []},
        }),
        isTrue,
      );
    });

    test('otro código o un cuerpo raro no', () {
      expect(isGuestExpiredResponse({'error': {'code': 'UNAUTHORIZED'}}), isFalse);
      expect(isGuestExpiredResponse('texto'), isFalse);
      expect(isGuestExpiredResponse(null), isFalse);
    });
  });
```

Run: `cd nutrilife && flutter test test/features/premium/premium_screen_test.dart test/core/network/dio_client_redirect_test.dart`
Expected: FAIL (no compilan: falta `isGuest` y `isGuestExpiredResponse`).

- [ ] **Step 3: Premium**

En `premium_screen.dart` (importar `../../../../core/services/session_service.dart`):

```dart
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.purchases, this.subscriptions, this.isGuest});

  final PurchaseService? purchases;
  final SubscriptionRepository? subscriptions;

  /// Solo para pruebas; por defecto lo dice la sesión.
  final bool? isGuest;
```

En el estado: `late final bool _isGuest = widget.isGuest ?? SessionService.isGuest;`

En `build`:

```dart
    final canBuy = !_isGuest && !_busy && (!_purchases.isEnabled || (_offer?.priceOf(_plan) != null));
```

Justo antes de `const SizedBox(height: 24),` que precede al `ElevatedButton`:

```dart
          if (_isGuest) ...[
            const SizedBox(height: 16),
            Text(
              l10n.premiumGuestBlocked,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w700),
            ),
          ],
```

Y el botón de restaurar: `TextButton(onPressed: _busy || _isGuest ? null : _restore, child: Text(l10n.premiumRestore)),`

- [ ] **Step 4: Aviso de vencimiento**

En `dio_client.dart`, importar `../l10n/l10n.dart` y agregar, después de `shouldRedirectToLogin`:

```dart
/// true si el 401 dice que venció la cuenta de invitado: el login lo avisa.
bool isGuestExpiredResponse(dynamic body) {
  if (body is! Map) return false;
  final error = body['error'];
  return error is Map && error['code'] == 'GUEST_EXPIRED';
}
```

En `onError`, la llamada pasa a:

```dart
                _redirectToLogin(
                  guestExpired: isGuestExpiredResponse(error.response?.data),
                );
```

Y `_redirectToLogin`:

```dart
  static Future<void> _redirectToLogin({bool guestExpired = false}) async {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    rateLimit.clear();
    await SessionService.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          notice: guestExpired ? currentL10n.authGuestExpired : null,
        ),
      ),
      (route) => false,
    );
    _isRedirectingToLogin = false;
  }
```

- [ ] **Step 5: Correr todo**

Run: `cd nutrilife && flutter analyze && flutter test`
Expected: `No issues found!` y todos los tests PASS (incluidos `arb_keys_test` y `english_layout_test`).

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/premium/presentation/screens/premium_screen.dart nutrilife/lib/core/network/dio_client.dart nutrilife/lib/l10n/ nutrilife/test/features/premium/premium_screen_test.dart nutrilife/test/core/network/dio_client_redirect_test.dart
git commit -m "feat(app): el invitado no compra y el login avisa cuando vence"
```

---

### Task 11: Verificación completa y despliegue

**Files:** ninguno nuevo.

- [ ] **Step 1: Todo en verde**

Run: `cd backend && npm test`
Run: `cd nutrilife && flutter analyze && flutter test`
Run: `cd admin-panel && npm run build`
Expected: todo PASS / sin errores.

- [ ] **Step 2: Probar el backend en local (si hay base de desarrollo)**

```bash
cd backend && npm run db:apply -- update_18_10_2026_guest_mode.sql
```

Revisar contra qué host va. Solo si es la base de desarrollo, correrlo otra vez con `--yes`. Luego levantar el backend con `GUEST_MODE_ENABLED=true` en el `.env` y:

```bash
curl -s -X POST http://localhost:3000/api/v1/auth/guest
```

Expected: 201 con `token`, `user.isGuest: true` y `guestExpiresAt` a 24 h. `GET /api/v1/auth/health` → `guestModeEnabled: true`.

- [ ] **Step 3: Despliegue (con el OK del usuario en cada paso)**

1. Migración en la base de producción: `npm run db:apply -- update_18_10_2026_guest_mode.sql --yes` con el `.env` de producción. **Antes** del push del backend: el código nuevo lee `guest_expires_at`.
2. Merge de la rama a `main` y push del backend (Dokploy despliega).
3. En Dokploy: `GUEST_MODE_ENABLED=true` (lo pone el usuario).
4. App: subir versión en `pubspec.yaml` y `flutter build appbundle --dart-define-from-file=dart_defines/play.json`.

- [ ] **Step 4: Prueba manual en el emulador**

`flutter run` y que el usuario pruebe: botón visible, alerta, inicio con datos y franja, Premium bloqueado, perfil sin "Eliminar cuenta".

## Al terminar la beta

`GUEST_MODE_ENABLED=false` en Dokploy. El botón desaparece en todas las versiones instaladas y en 24 horas el job borra al último invitado.
