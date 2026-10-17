# Límite diario del Chef IA — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Limitar el Chef IA a 3 mensajes al día para FREE y a 50 (oculto) para PRO, y mostrarlo en la app con un contador y una tarjeta de bloqueo que lleva a Premium.

**Architecture:** El backend descuenta cada mensaje en Redis (`quota:chat:{userId}:{día Bogotá}`) con un middleware que va después del rate limit por minuto. Si n8n falla, devuelve el mensaje. La cuota viaja en cada respuesta del chat y en `GET /chat/quota`. La app la guarda en `ChatViewModel`, la pinta con `ChatQuotaChip` y, al agotarse, cambia el input por `ChatQuotaBlockedCard`.

**Tech Stack:** Node.js + Express (ESM), node-redis 4, PostgreSQL (`pg`), `node --test` con `mock.module`; Flutter + Dio, ARB / `flutter gen-l10n`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-17-chef-ia-limite-diario-design.md`

## Global Constraints

- FREE: **3 mensajes al día**. PRO: **50 al día**, sin mostrar el número. ADMIN (rol): sin límite. Un plan desconocido usa el límite FREE.
- Los límites se pueden sobreescribir con `CHAT_DAILY_LIMIT_FREE` y `CHAT_DAILY_LIMIT_PRO`.
- El día cambia a la **medianoche de America/Bogota (UTC-5, sin horario de verano)**.
- Códigos de error: `CHAT_DAILY_LIMIT` (FREE) y `CHAT_FAIR_USE_LIMIT` (PRO), los dos con status 429. `N8N_ERROR` pasa de 500 a **503**.
- Forma de la cuota en el backend: `{ plan, unlimited, limit, used, remaining, resetAt, exhausted }`. Con `unlimited: true`, `limit`, `used` y `remaining` van en `null`.
- Si Redis se cae, el mensaje pasa (fail-open) y `quota` va en `null`.
- Todo texto que ve el usuario va en español e inglés: en el backend por `src/i18n/messages.js` y en la app por `lib/l10n/app_es.arb` + `lib/l10n/app_en.arb`. Nunca texto fijo en widgets.
- Commits **sin** línea `Co-Authored-By` de Claude.
- Backend: `git pull` antes de empezar y commit por tarea. El push a `main` va al final del backend (Tarea 5).
- App (`nutrilife/`): commits locales por tarea. **No hacer push sin preguntar al usuario.**
- El flujo de n8n no se toca.
- Hay cambios previos sin commitear en `nutrilife/lib/l10n/app_localizations*.dart` y `nutrilife/macos/Flutter/GeneratedPluginRegistrant.swift` (solo fines de línea). No incluir `GeneratedPluginRegistrant.swift` en ningún commit.

## Mapa de archivos

Backend (`backend/`):
- Crear `src/utils/bogotaDay.js`: día y próxima medianoche en Bogotá.
- Crear `src/config/plan_limits.js`: límites por plan.
- Modificar `src/config/env_config.js`: bloque `chatQuota`.
- Crear `src/modules/chat/chatQuota.repository.js`: plan del usuario desde la base de datos.
- Crear `src/modules/chat/chatQuota.service.js`: `getChatQuota` y `consumeChatQuota`.
- Crear `src/middleware/chatQuota.middleware.js`: `chatDailyQuota`.
- Modificar `src/utils/response.js`: `errorResponse` acepta un `data` opcional.
- Modificar `src/i18n/messages.js`: `CHAT_DAILY_LIMIT`, `CHAT_FAIR_USE_LIMIT` y el nuevo `N8N_ERROR`.
- Crear `src/modules/chat/chatMessage.controller.js`: el handler de `POST /n8n/chat`, sacado de `app.js`.
- Modificar `src/utils/n8n.service.js`: error 503 con mensaje amigable.
- Modificar `src/app.js`: monta `chatDailyQuota` y el controller nuevo.
- Crear `src/modules/chat/chatQuota.controller.js` y modificar `src/modules/chat/chat.routes.js`: `GET /chat/quota`.
- Tests en `test/chat/*.test.js` y `test/utils/n8n.service.test.js`.

App (`nutrilife/`):
- Crear `lib/features/chatbot/data/models/chat_quota_model.dart`: `ChatQuota` + `ChatQuotaExceededException`.
- Modificar `lib/core/network/api_routes.dart`: `chatQuota`.
- Modificar `lib/features/chatbot/data/chat_repository.dart`: `getQuota()`, `ChatResponse.quota` y el 429 de cuota.
- Modificar `lib/features/chatbot/presentation/controllers/chat_view_model.dart`: estado de la cuota.
- Modificar `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb` (+ regenerar `app_localizations*.dart`).
- Crear `lib/features/chatbot/presentation/widgets/chat_quota_chip.dart`.
- Crear `lib/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart`.
- Modificar `lib/features/chatbot/presentation/screens/ai_chat_view.dart`.
- Tests en `test/features/chatbot/`.

---

### Task 1: Día de Bogotá y límites por plan

**Files:**
- Create: `backend/src/utils/bogotaDay.js`
- Create: `backend/src/config/plan_limits.js`
- Modify: `backend/src/config/env_config.js` (bloque `rateLimit`, líneas 46-51)
- Test: `backend/test/chat/bogotaDay.test.js`, `backend/test/chat/plan_limits.test.js`

**Interfaces:**
- Produces: `bogotaDayKey(now?: Date): string` → `'YYYY-MM-DD'`; `nextBogotaMidnight(now?: Date): Date`; `CHAT_DAILY_LIMITS: { FREE: number, PRO: number }`; `chatDailyLimitFor(plan: string|null): number`; `config.chatQuota.freePerDay`, `config.chatQuota.proPerDay`.

- [ ] **Step 1: Traer main al día**

Run: `cd backend && git pull`
Expected: `Already up to date.` o fast-forward sin conflictos.

- [ ] **Step 2: Escribir los tests que fallan**

`backend/test/chat/bogotaDay.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { bogotaDayKey, nextBogotaMidnight } = await import(src('utils/bogotaDay.js'));

test('antes de las 05:00 UTC sigue siendo el día anterior en Bogotá', () => {
  assert.equal(bogotaDayKey(new Date('2026-10-17T04:59:59Z')), '2026-10-16');
});

test('a las 05:00 UTC empieza el día en Bogotá', () => {
  assert.equal(bogotaDayKey(new Date('2026-10-17T05:00:00Z')), '2026-10-17');
});

test('la próxima medianoche justo antes del cambio es en un segundo', () => {
  assert.equal(
    nextBogotaMidnight(new Date('2026-10-17T04:59:59Z')).toISOString(),
    '2026-10-17T05:00:00.000Z'
  );
});

test('justo en la medianoche, la próxima es la del día siguiente', () => {
  assert.equal(
    nextBogotaMidnight(new Date('2026-10-17T05:00:00Z')).toISOString(),
    '2026-10-18T05:00:00.000Z'
  );
});

test('cambia de mes sin problema', () => {
  assert.equal(
    nextBogotaMidnight(new Date('2026-10-31T20:00:00Z')).toISOString(),
    '2026-11-01T05:00:00.000Z'
  );
});
```

`backend/test/chat/plan_limits.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { CHAT_DAILY_LIMITS, chatDailyLimitFor } = await import(src('config/plan_limits.js'));

test('por defecto FREE tiene 3 mensajes y PRO 50', () => {
  assert.equal(CHAT_DAILY_LIMITS.FREE, 3);
  assert.equal(CHAT_DAILY_LIMITS.PRO, 50);
});

test('cada plan conocido usa su límite', () => {
  assert.equal(chatDailyLimitFor('FREE'), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor('PRO'), CHAT_DAILY_LIMITS.PRO);
});

test('un plan desconocido o vacío usa el límite FREE', () => {
  assert.equal(chatDailyLimitFor('GOLD'), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor(null), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor('constructor'), CHAT_DAILY_LIMITS.FREE);
});
```

- [ ] **Step 3: Correr los tests y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/bogotaDay.test.js test/chat/plan_limits.test.js`
Expected: FAIL con `Cannot find module .../src/utils/bogotaDay.js` (y lo mismo para `plan_limits.js`).

- [ ] **Step 4: Implementar**

`backend/src/utils/bogotaDay.js`:

```js
// Bogotá está en UTC-5 todo el año (no tiene horario de verano): basta un
// desplazamiento fijo para saber en qué día va el usuario.
const BOGOTA_OFFSET_MS = 5 * 60 * 60 * 1000;

const toBogota = (now) => new Date(now.getTime() - BOGOTA_OFFSET_MS);

/** Día en Bogotá como 'YYYY-MM-DD'. */
export const bogotaDayKey = (now = new Date()) => toBogota(now).toISOString().slice(0, 10);

/** Instante (UTC) de la próxima medianoche de Bogotá. */
export const nextBogotaMidnight = (now = new Date()) => {
  const local = toBogota(now);
  local.setUTCHours(24, 0, 0, 0);
  return new Date(local.getTime() + BOGOTA_OFFSET_MS);
};
```

En `backend/src/config/env_config.js`, justo después del bloque `rateLimit: { ... },` (antes del `};` final):

```js
  chatQuota: {
    freePerDay: Number(trim(env.CHAT_DAILY_LIMIT_FREE)) || 3,
    proPerDay: Number(trim(env.CHAT_DAILY_LIMIT_PRO)) || 50,
  },
```

`backend/src/config/plan_limits.js`:

```js
import { config } from './env_config.js';

// Límites por plan. Las siguientes partes (recetas guardadas, progreso)
// agregan aquí los suyos. El rol ADMIN no tiene límite; eso lo decide quien
// consulta, no esta tabla.
export const CHAT_DAILY_LIMITS = Object.freeze({
  FREE: config.chatQuota.freePerDay,
  PRO: config.chatQuota.proPerDay,
});

/** Mensajes del Chef IA al día para un plan. Un plan desconocido usa FREE. */
export const chatDailyLimitFor = (plan) =>
  typeof plan === 'string' && Object.hasOwn(CHAT_DAILY_LIMITS, plan)
    ? CHAT_DAILY_LIMITS[plan]
    : CHAT_DAILY_LIMITS.FREE;
```

- [ ] **Step 5: Correr los tests y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/bogotaDay.test.js test/chat/plan_limits.test.js`
Expected: PASS, 8 tests.

- [ ] **Step 6: Commit**

```bash
git add backend/src/utils/bogotaDay.js backend/src/config/plan_limits.js backend/src/config/env_config.js backend/test/chat/bogotaDay.test.js backend/test/chat/plan_limits.test.js
git commit -m "feat(chat): día de Bogotá y límites de mensajes por plan"
```

---

### Task 2: Servicio de cuota (Redis + plan del usuario)

**Files:**
- Create: `backend/src/modules/chat/chatQuota.repository.js`
- Create: `backend/src/modules/chat/chatQuota.service.js`
- Test: `backend/test/chat/chatQuota.service.test.js`

**Interfaces:**
- Consumes: `bogotaDayKey`, `nextBogotaMidnight` (Task 1); `chatDailyLimitFor` (Task 1); `getRedisClient()` de `src/config/redis.client.js` (cliente node-redis 4: `get`, `incr`, `decr`, `expireAt`).
- Produces:
  - `findUserPlanById(userId: number): Promise<string|null>`
  - `getChatQuota(user: {userId, role}, now?: Date): Promise<Quota|null>`. Devuelve `null` si Redis no responde.
  - `consumeChatQuota(user, now?: Date): Promise<{ allowed: boolean, quota: Quota|null, refund: () => Promise<void> }>`
  - `Quota = { plan: string|null, unlimited: boolean, limit: number|null, used: number|null, remaining: number|null, resetAt: string (ISO), exhausted: boolean }`
  - Las dos funciones lanzan `AppError('User not found', 401, 'UNAUTHORIZED')` si el usuario no existe.

- [ ] **Step 1: Escribir el test que falla**

`backend/test/chat/chatQuota.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// Redis en memoria: lo justo que usa el servicio.
const store = new Map();
const expirations = new Map();
let redisDown = false;
const fakeRedis = {
  get: async (key) => (store.has(key) ? String(store.get(key)) : null),
  incr: async (key) => {
    const value = (store.get(key) ?? 0) + 1;
    store.set(key, value);
    return value;
  },
  decr: async (key) => {
    const value = (store.get(key) ?? 0) - 1;
    store.set(key, value);
    return value;
  },
  expireAt: async (key, unixSeconds) => {
    expirations.set(key, unixSeconds);
    return true;
  },
};

let plans = {};
mock.module(src('config/redis.client.js'), {
  namedExports: {
    getRedisClient: async () => {
      if (redisDown) throw new Error('ECONNREFUSED');
      return fakeRedis;
    },
  },
});
mock.module(src('modules/chat/chatQuota.repository.js'), {
  namedExports: { findUserPlanById: async (userId) => plans[userId] ?? null },
});

const { AppError } = await import(src('utils/AppError.js'));
const { consumeChatQuota, getChatQuota } = await import(src('modules/chat/chatQuota.service.js'));

const NOW = new Date('2026-10-17T15:00:00Z'); // 10:00 a. m. en Bogotá
const TOMORROW = new Date('2026-10-18T06:00:00Z');
const RESET_AT = '2026-10-18T05:00:00.000Z';
const FREE_USER = { userId: 1, role: 'USER' };
const PRO_USER = { userId: 2, role: 'USER' };
const ADMIN = { userId: 3, role: 'ADMIN' };

beforeEach(() => {
  store.clear();
  expirations.clear();
  redisDown = false;
  plans = { 1: 'FREE', 2: 'PRO' };
});

const consumeTimes = async (user, times, now = NOW) => {
  let last;
  for (let i = 0; i < times; i++) last = await consumeChatQuota(user, now);
  return last;
};

test('FREE: el primer mensaje deja 2 de 3', async () => {
  const { allowed, quota } = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(allowed, true);
  assert.deepEqual(quota, {
    plan: 'FREE',
    unlimited: false,
    limit: 3,
    used: 1,
    remaining: 2,
    resetAt: RESET_AT,
    exhausted: false,
  });
});

test('FREE: el tercero agota y el cuarto se rechaza sin inflar el contador', async () => {
  const third = await consumeTimes(FREE_USER, 3);
  assert.equal(third.allowed, true);
  assert.equal(third.quota.exhausted, true);

  const fourth = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(fourth.allowed, false);
  assert.equal(fourth.quota.remaining, 0);
  assert.equal(fourth.quota.used, 3);
  assert.equal(store.get('quota:chat:1:2026-10-17'), 3);
});

test('la clave expira una hora después de la medianoche de Bogotá', async () => {
  await consumeChatQuota(FREE_USER, NOW);
  assert.equal(
    expirations.get('quota:chat:1:2026-10-17'),
    Date.parse(RESET_AT) / 1000 + 3600
  );
});

test('al día siguiente el contador arranca de nuevo', async () => {
  await consumeTimes(FREE_USER, 3);
  const next = await consumeChatQuota(FREE_USER, TOMORROW);
  assert.equal(next.allowed, true);
  assert.equal(next.quota.used, 1);
});

test('PRO: se ve ilimitado y se corta en el mensaje 51', async () => {
  const fiftieth = await consumeTimes(PRO_USER, 50);
  assert.equal(fiftieth.allowed, true);
  assert.equal(fiftieth.quota.unlimited, true);
  assert.equal(fiftieth.quota.limit, null);
  assert.equal(fiftieth.quota.remaining, null);

  const fiftyFirst = await consumeChatQuota(PRO_USER, NOW);
  assert.equal(fiftyFirst.allowed, false);
  assert.equal(fiftyFirst.quota.unlimited, true);
  assert.equal(fiftyFirst.quota.exhausted, true);
});

test('ADMIN nunca cuenta', async () => {
  const result = await consumeTimes(ADMIN, 100);
  assert.equal(result.allowed, true);
  assert.equal(result.quota.unlimited, true);
  assert.equal(result.quota.exhausted, false);
  assert.equal(store.size, 0);
});

test('refund devuelve el mensaje', async () => {
  const { refund } = await consumeChatQuota(FREE_USER, NOW);
  await refund();
  assert.equal(store.get('quota:chat:1:2026-10-17'), 0);
});

test('con Redis caído deja pasar sin cuota', async () => {
  redisDown = true;
  const result = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(result.allowed, true);
  assert.equal(result.quota, null);
  await result.refund(); // no lanza
});

test('un usuario que no existe es 401', async () => {
  await assert.rejects(
    consumeChatQuota({ userId: 99, role: 'USER' }, NOW),
    (error) => error instanceof AppError && error.status === 401 && error.code === 'UNAUTHORIZED'
  );
});

test('getChatQuota lee sin consumir', async () => {
  await consumeTimes(FREE_USER, 2);
  const first = await getChatQuota(FREE_USER, NOW);
  const second = await getChatQuota(FREE_USER, NOW);
  assert.equal(first.used, 2);
  assert.equal(second.used, 2);
  assert.equal(second.remaining, 1);
});

test('getChatQuota de un usuario nuevo es 0 de 3', async () => {
  const quota = await getChatQuota(FREE_USER, NOW);
  assert.equal(quota.used, 0);
  assert.equal(quota.remaining, 3);
  assert.equal(quota.exhausted, false);
});

test('getChatQuota con Redis caído es null', async () => {
  redisDown = true;
  assert.equal(await getChatQuota(FREE_USER, NOW), null);
});
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatQuota.service.test.js`
Expected: FAIL con `Cannot find module .../src/modules/chat/chatQuota.service.js`.

- [ ] **Step 3: Implementar**

`backend/src/modules/chat/chatQuota.repository.js`:

```js
import pool from '../../database/connection.js';

/** Nombre del plan del usuario (FREE / PRO), o null si el usuario no existe. */
export const findUserPlanById = async (userId) => {
  const { rows } = await pool.query(
    `SELECT p.name AS plan
       FROM users u
       INNER JOIN plans p ON p.plan_id = u.plan_id
      WHERE u.user_id = $1`,
    [userId]
  );
  return rows[0]?.plan ?? null;
};
```

`backend/src/modules/chat/chatQuota.service.js`:

```js
import { getRedisClient } from '../../config/redis.client.js';
import { chatDailyLimitFor } from '../../config/plan_limits.js';
import { AppError } from '../../utils/AppError.js';
import { bogotaDayKey, nextBogotaMidnight } from '../../utils/bogotaDay.js';
import { findUserPlanById } from './chatQuota.repository.js';

// Margen sobre la medianoche: la clave no debe expirar antes de cambiar de día.
const EXPIRY_MARGIN_SECONDS = 60 * 60;
const noop = async () => {};

const quotaKey = (userId, now) => `quota:chat:${userId}:${bogotaDayKey(now)}`;

// El plan se lee de la base de datos y no del JWT: un cambio de plan desde el
// admin aplica en el siguiente mensaje.
const resolveLimits = async (user) => {
  if (user.role === 'ADMIN') return { plan: null, unlimited: true, limit: null };
  const plan = await findUserPlanById(user.userId);
  if (!plan) throw new AppError('User not found', 401, 'UNAUTHORIZED');
  return { plan, unlimited: plan === 'PRO', limit: chatDailyLimitFor(plan) };
};

// PRO ve "ilimitado": su tope de uso justo no sale en la respuesta.
const buildQuota = ({ plan, unlimited, limit, used, now }) => ({
  plan,
  unlimited,
  limit: unlimited ? null : limit,
  used: unlimited ? null : Math.min(used, limit),
  remaining: unlimited ? null : Math.max(0, limit - used),
  resetAt: nextBogotaMidnight(now).toISOString(),
  exhausted: limit !== null && used >= limit,
});

/** Cuota de hoy sin consumir. null si Redis no responde. */
export const getChatQuota = async (user, now = new Date()) => {
  const limits = await resolveLimits(user);
  if (limits.limit === null) return buildQuota({ ...limits, used: 0, now });

  try {
    const redis = await getRedisClient();
    const used = Number(await redis.get(quotaKey(user.userId, now))) || 0;
    return buildQuota({ ...limits, used, now });
  } catch (error) {
    console.error('[chatQuota] Redis no disponible:', error.message);
    return null;
  }
};

/**
 * Descuenta un mensaje de hoy. Si ya no quedan, no descuenta y devuelve
 * allowed: false. refund() devuelve el mensaje cuando n8n falla.
 * Con Redis caído deja pasar sin contar (igual que el rate limit).
 */
export const consumeChatQuota = async (user, now = new Date()) => {
  const limits = await resolveLimits(user);
  if (limits.limit === null) {
    return { allowed: true, quota: buildQuota({ ...limits, used: 0, now }), refund: noop };
  }

  const key = quotaKey(user.userId, now);
  let redis;
  let used;
  try {
    redis = await getRedisClient();
    used = await redis.incr(key);
    if (used === 1) {
      const midnight = Math.floor(nextBogotaMidnight(now).getTime() / 1000);
      await redis.expireAt(key, midnight + EXPIRY_MARGIN_SECONDS);
    }
    if (used > limits.limit) {
      await redis.decr(key);
      return {
        allowed: false,
        quota: buildQuota({ ...limits, used: limits.limit, now }),
        refund: noop,
      };
    }
  } catch (error) {
    console.error('[chatQuota] Redis no disponible, se deja pasar:', error.message);
    return { allowed: true, quota: null, refund: noop };
  }

  const refund = async () => {
    try {
      await redis.decr(key);
    } catch (error) {
      console.error('[chatQuota] no se pudo devolver el mensaje:', error.message);
    }
  };
  return { allowed: true, quota: buildQuota({ ...limits, used, now }), refund };
};
```

- [ ] **Step 4: Correr el test y ver que pasa**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatQuota.service.test.js`
Expected: PASS, 12 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/src/modules/chat/chatQuota.repository.js backend/src/modules/chat/chatQuota.service.js backend/test/chat/chatQuota.service.test.js
git commit -m "feat(chat): cuota diaria de mensajes por plan en Redis"
```

---

### Task 3: Middleware `chatDailyQuota` y mensajes del límite

**Files:**
- Create: `backend/src/middleware/chatQuota.middleware.js`
- Modify: `backend/src/utils/response.js` (`errorResponse`)
- Modify: `backend/src/i18n/messages.js` (`CODE_MESSAGES.en`, sección `// Chat`)
- Test: `backend/test/chat/chatQuota.middleware.test.js`

**Interfaces:**
- Consumes: `consumeChatQuota` (Task 2).
- Produces:
  - `chatDailyQuota(req, res, next)`. Si deja pasar, pone `req.chatQuota = { quota: Quota|null, refund: () => Promise<void> }`. Si rechaza, responde 429 `{ success: false, message, error: { code, details: [] }, data: { quota } }`.
  - `errorResponse(res, message, code, status, details, data?)`: si `data !== undefined`, lo agrega como `data` en el body.

- [ ] **Step 1: Escribir el test que falla**

`backend/test/chat/chatQuota.middleware.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let consumeImpl;
mock.module(src('modules/chat/chatQuota.service.js'), {
  namedExports: { consumeChatQuota: (...args) => consumeImpl(...args) },
});

const { chatDailyQuota } = await import(src('middleware/chatQuota.middleware.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

const freeExhausted = {
  plan: 'FREE', unlimited: false, limit: 3, used: 3, remaining: 0,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: true,
};
const proExhausted = {
  plan: 'PRO', unlimited: true, limit: null, used: null, remaining: null,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: true,
};

test('FREE sin mensajes: 429 CHAT_DAILY_LIMIT en español con la cuota', async () => {
  consumeImpl = async () => ({ allowed: false, quota: freeExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ user: { userId: 1, role: 'USER' } }, res, () => assert.fail('no debe pasar'));

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'CHAT_DAILY_LIMIT');
  assert.equal(res.body.message, 'Usaste tus 3 mensajes de hoy con el Chef IA.');
  assert.deepEqual(res.body.data, { quota: freeExhausted });
});

test('FREE sin mensajes: el mensaje sale en inglés', async () => {
  consumeImpl = async () => ({ allowed: false, quota: freeExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ lang: 'en', user: { userId: 1, role: 'USER' } }, res, () => {});

  assert.equal(res.body.message, "You've used your 3 Chef AI messages for today.");
});

test('PRO en el tope: 429 CHAT_FAIR_USE_LIMIT', async () => {
  consumeImpl = async () => ({ allowed: false, quota: proExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ user: { userId: 2, role: 'USER' } }, res, () => {});

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'CHAT_FAIR_USE_LIMIT');
  assert.equal(res.body.message, 'Llegaste al límite de uso justo de hoy. Vuelve mañana.');
});

test('con mensajes disponibles deja pasar y guarda la cuota en req', async () => {
  const refund = async () => {};
  const quota = { ...freeExhausted, used: 1, remaining: 2, exhausted: false };
  consumeImpl = async () => ({ allowed: true, quota, refund });
  const req = { user: { userId: 1, role: 'USER' } };
  let nextCalls = 0;
  await chatDailyQuota(req, fakeRes(), (error) => {
    assert.equal(error, undefined);
    nextCalls++;
  });

  assert.equal(nextCalls, 1);
  assert.equal(req.chatQuota.quota, quota);
  assert.equal(req.chatQuota.refund, refund);
});

test('un error del servicio va al manejador de errores', async () => {
  const boom = new Error('db caída');
  consumeImpl = async () => {
    throw boom;
  };
  let received;
  await chatDailyQuota({ user: { userId: 1, role: 'USER' } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, boom);
});
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatQuota.middleware.test.js`
Expected: FAIL con `Cannot find module .../src/middleware/chatQuota.middleware.js`.

- [ ] **Step 3: `errorResponse` acepta `data`**

En `backend/src/utils/response.js`, reemplazar `errorResponse` y su comentario por:

```js
/*
 * response: Object - Objeto de respuesta
 * message: string - Mensaje de error
 * code: string - Código de error de la aplicación
 * status: number - Código de estado HTTP (por defecto: 500)
 * details: Array - Detalles adicionales del error (ej: errores de validación)
 * data: any - Datos opcionales para el cliente (ej: la cuota del chat en un 429)
*/
export const errorResponse = (res, message = 'Error interno del servidor', code = 'INTERNAL_ERROR', status = 500, details = [], data = undefined) => {
  const body = {
    success: false,
    message,
    error: {
      code,
      details
    }
  };
  if (data !== undefined) body.data = data;
  return res.status(status).json(body);
};
```

- [ ] **Step 4: Mensajes en inglés**

En `backend/src/i18n/messages.js`, dentro de `CODE_MESSAGES.en`, en la sección `// Chat`, reemplazar la línea `N8N_ERROR: 'We could not reach the chat service.',` por:

```js
    N8N_ERROR: 'The Chef is taking a short break. Try again in a little while.',
    CHAT_DAILY_LIMIT: ({ limit } = {}) =>
      limit
        ? `You've used your ${limit} Chef AI message${limit === 1 ? '' : 's'} for today.`
        : "You've used your Chef AI messages for today.",
    CHAT_FAIR_USE_LIMIT: "You've reached today's fair-use limit. Come back tomorrow.",
```

- [ ] **Step 5: Implementar el middleware**

`backend/src/middleware/chatQuota.middleware.js`:

```js
import { consumeChatQuota } from '../modules/chat/chatQuota.service.js';
import { errorResponse } from '../utils/response.js';
import { localizeError } from '../i18n/localize.js';

/**
 * Límite diario del Chef IA. Va después de chatRateLimit en POST /n8n/chat.
 * Deja en req.chatQuota la cuota ya descontada y refund() para devolver el
 * mensaje si n8n falla.
 */
export const chatDailyQuota = async (req, res, next) => {
  try {
    const { allowed, quota, refund } = await consumeChatQuota(req.user);
    if (allowed) {
      req.chatQuota = { quota, refund };
      return next();
    }

    const fairUse = quota.unlimited;
    const code = fairUse ? 'CHAT_FAIR_USE_LIMIT' : 'CHAT_DAILY_LIMIT';
    const source = fairUse
      ? 'Llegaste al límite de uso justo de hoy. Vuelve mañana.'
      : `Usaste tus ${quota.limit} mensaje${quota.limit === 1 ? '' : 's'} de hoy con el Chef IA.`;
    const { message } = localizeError(
      { code, message: source, params: { limit: quota.limit } },
      req.lang
    );
    return errorResponse(res, message, code, 429, [], { quota });
  } catch (error) {
    return next(error);
  }
};
```

- [ ] **Step 6: Correr los tests y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatQuota.middleware.test.js test/i18n/coverage.test.js test/i18n/rateLimit.middleware.test.js`
Expected: PASS todos.

- [ ] **Step 7: Commit**

```bash
git add backend/src/middleware/chatQuota.middleware.js backend/src/utils/response.js backend/src/i18n/messages.js backend/test/chat/chatQuota.middleware.test.js
git commit -m "feat(chat): middleware del límite diario con 429 en español e inglés"
```

---

### Task 4: `POST /n8n/chat` con cuota, devolución y error amigable

**Files:**
- Create: `backend/src/modules/chat/chatMessage.controller.js`
- Modify: `backend/src/utils/n8n.service.js:23-26` (el `catch`)
- Modify: `backend/src/app.js:17-25` (imports) y `:56-129` (swagger + handler del chat)
- Test: `backend/test/chat/chatMessage.controller.test.js`, `backend/test/utils/n8n.service.test.js`

**Interfaces:**
- Consumes: `req.chatQuota = { quota, refund }` (Task 3); `chatDailyQuota` (Task 3); `sendChatN8n(message, userId, name, token, attachedFoods, lang)` y `getFridgeItemsByIdsService(userId, fridgeItemIds, foodIds)`, que ya existen.
- Produces: `sendChatMessageController(req, res)`. Si va bien, responde `200 { success, message, data: { ...respuestaN8n, quota } }`. Si falla, llama a `refund()` y responde con el error localizado.

- [ ] **Step 1: Escribir los tests que fallan**

`backend/test/chat/chatMessage.controller.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let sendImpl;
mock.module(src('utils/n8n.service.js'), {
  namedExports: { sendChatN8n: (...args) => sendImpl(...args) },
});
mock.module(src('modules/fridge/fridge.service.js'), {
  namedExports: { getFridgeItemsByIdsService: async () => [] },
});

const { AppError } = await import(src('utils/AppError.js'));
const { sendChatMessageController } = await import(src('modules/chat/chatMessage.controller.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

const quota = {
  plan: 'FREE', unlimited: false, limit: 3, used: 1, remaining: 2,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: false,
};
let refunds;
const buildReq = (overrides = {}) => ({
  body: { message: 'quiero un desayuno' },
  user: { userId: 1, name: 'Ana' },
  headers: { authorization: 'Bearer jwt' },
  chatQuota: {
    quota,
    refund: async () => {
      refunds++;
    },
  },
  ...overrides,
});

beforeEach(() => {
  refunds = 0;
  sendImpl = async () => ({ type: 'CHAT', message: 'hola', recipe: null });
});

test('la respuesta del chat trae la cuota', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq(), res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.type, 'CHAT');
  assert.deepEqual(res.body.data.quota, quota);
  assert.equal(refunds, 0);
});

test('con Redis caído la cuota va en null', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ chatQuota: { quota: null, refund: async () => {} } }), res);

  assert.equal(res.body.data.quota, null);
});

test('si n8n falla devuelve el mensaje y responde 503 amigable', async () => {
  sendImpl = async () => {
    throw new AppError('El Chef está descansando un momento. Intenta de nuevo en un rato.', 503, 'N8N_ERROR');
  };
  const res = fakeRes();
  await sendChatMessageController(buildReq(), res);

  assert.equal(refunds, 1);
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.error.code, 'N8N_ERROR');
  assert.equal(res.body.message, 'El Chef está descansando un momento. Intenta de nuevo en un rato.');
});

test('el error amigable sale en inglés', async () => {
  sendImpl = async () => {
    throw new AppError('El Chef está descansando un momento. Intenta de nuevo en un rato.', 503, 'N8N_ERROR');
  };
  const res = fakeRes();
  await sendChatMessageController(buildReq({ lang: 'en' }), res);

  assert.equal(res.body.message, 'The Chef is taking a short break. Try again in a little while.');
});

test('un mensaje vacío no cuenta', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ body: { message: '' } }), res);

  assert.equal(res.statusCode, 400);
  assert.equal(refunds, 1);
});

test('sin req.chatQuota no revienta', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ chatQuota: undefined }), res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.quota, null);
});
```

En `backend/test/utils/n8n.service.test.js`, cambiar el mock de axios para poder forzar un fallo y agregar un test al final:

```js
const posts = [];
let failNext = false;
mock.module('axios', {
  exports: {
    default: {
      post: async (url, payload) => {
        posts.push(payload);
        if (failNext) {
          failNext = false;
          throw new Error('socket hang up');
        }
        return { data: { ok: true } };
      },
    },
  },
});
```

```js
test('si n8n falla el error es 503 con mensaje amigable', async () => {
  failNext = true;
  await assert.rejects(sendChatN8n('hola', 7, 'Ana', 'jwt'), (error) => {
    assert.equal(error.status, 503);
    assert.equal(error.code, 'N8N_ERROR');
    assert.equal(error.message, 'El Chef está descansando un momento. Intenta de nuevo en un rato.');
    return true;
  });
});
```

- [ ] **Step 2: Correr los tests y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatMessage.controller.test.js test/utils/n8n.service.test.js`
Expected: FAIL. El controller no existe y el test nuevo de n8n recibe `status 500`.

- [ ] **Step 3: Error amigable en n8n.service**

En `backend/src/utils/n8n.service.js`, reemplazar la línea del `throw` dentro del `catch` por:

```js
    // 503: el servicio de IA no responde (n8n caído o MiniMax sin cuota).
    throw new AppError("El Chef está descansando un momento. Intenta de nuevo en un rato.", 503, "N8N_ERROR");
```

- [ ] **Step 4: Crear el controller**

`backend/src/modules/chat/chatMessage.controller.js`:

```js
import { AppError } from '../../utils/AppError.js';
import { errorResponse, successResponse } from '../../utils/response.js';
import { localizeError } from '../../i18n/localize.js';
import { sendChatN8n } from '../../utils/n8n.service.js';
import { getFridgeItemsByIdsService } from '../fridge/fridge.service.js';

// La respuesta de n8n es un objeto (type, message, recipe...): la cuota va a su lado.
const withQuota = (result, quota) =>
  result && typeof result === 'object' && !Array.isArray(result) ? { ...result, quota } : result;

export const sendChatMessageController = async (req, res) => {
  try {
    const { message, fridgeItemIds, foodIds } = req.body;
    const { userId, name } = req.user;
    const token = req.headers.authorization?.split(' ')[1];

    if (!message) throw new AppError('Bad request', 400, 'BAD_REQUEST');

    // Los ids se releen de la nevera y del catálogo visible para el usuario
    // autenticado: lo que el cliente mande y no sea suyo nunca llega a n8n.
    const attachedFoods = await getFridgeItemsByIdsService(userId, fridgeItemIds, foodIds);

    const result = await sendChatN8n(message, userId, name, token, attachedFoods, req.lang);
    return successResponse(
      res,
      withQuota(result, req.chatQuota?.quota ?? null),
      'Mensaje enviado correctamente a n8n'
    );
  } catch (error) {
    // Un mensaje sin respuesta no cuenta para el límite del día.
    await req.chatQuota?.refund();
    const { message, details } = localizeError(error, req.lang);
    return errorResponse(res, message, error.code, error.status, details);
  }
};
```

- [ ] **Step 5: Conectar en app.js**

En `backend/src/app.js`:

1. Agregar a los imports:
```js
import { chatDailyQuota } from './middleware/chatQuota.middleware.js';
import { sendChatMessageController } from './modules/chat/chatMessage.controller.js';
```
2. Reemplazar todo el `app.post('/api/v1/n8n/chat', ... });` (líneas 112-129) por:
```js
app.post('/api/v1/n8n/chat', authenticateToken(['ADMIN', 'USER']), chatRateLimit, chatDailyQuota, sendChatMessageController);
```
3. En el bloque `@openapi` de arriba de esa ruta, cambiar la respuesta `500` por estas respuestas:
```
 *       429:
 *         description: Límite por minuto (RATE_LIMIT_EXCEEDED) o del día (CHAT_DAILY_LIMIT para FREE, CHAT_FAIR_USE_LIMIT para PRO). Los del día traen data.quota.
 *       503:
 *         description: El servicio de IA no responde (N8N_ERROR). El mensaje no cuenta para el límite.
```
4. Quitar los imports que quedaron sin uso. Revisa cada uno con:
Run: `cd backend && for n in sendChatN8n getFridgeItemsByIdsService AppError localizeError errorResponse successResponse; do echo "$n: $(grep -c "\b$n\b" src/app.js)"; done`
Borra del import cada nombre que solo aparezca 1 vez (la línea del import). Si `errorResponse` y `successResponse` quedan los dos sin uso, borra la línea completa de `./utils/response.js`.

- [ ] **Step 6: Correr los tests y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatMessage.controller.test.js test/utils/n8n.service.test.js`
Expected: PASS todos.

Run: `cd backend && node -e "import('./src/app.js').then(() => { console.log('app ok'); process.exit(0); })"`
Expected: `app ok`. Confirma que `app.js` carga sin imports rotos. Si falla por variables de entorno que faltan (DB/n8n) y no por un import, también vale.

- [ ] **Step 7: Commit**

```bash
git add backend/src/modules/chat/chatMessage.controller.js backend/src/utils/n8n.service.js backend/src/app.js backend/test/chat/chatMessage.controller.test.js backend/test/utils/n8n.service.test.js
git commit -m "feat(chat): el chat descuenta la cuota diaria y la devuelve si n8n falla"
```

---

### Task 5: `GET /api/v1/chat/quota` y push del backend

**Files:**
- Create: `backend/src/modules/chat/chatQuota.controller.js`
- Modify: `backend/src/modules/chat/chat.routes.js` (imports + ruta nueva antes de `export default router`)
- Test: `backend/test/chat/chatQuota.controller.test.js`

**Interfaces:**
- Consumes: `getChatQuota(user)` (Task 2).
- Produces: `GET /api/v1/chat/quota` → `200 { success, message, data: Quota|null }`. La app (Task 6) lo llama como `ApiRoutes.chatQuota = '/chat/quota'`.

- [ ] **Step 1: Escribir el test que falla**

`backend/test/chat/chatQuota.controller.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let getImpl;
mock.module(src('modules/chat/chatQuota.service.js'), {
  namedExports: { getChatQuota: (...args) => getImpl(...args) },
});

const { getChatQuotaController } = await import(src('modules/chat/chatQuota.controller.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

test('devuelve la cuota del usuario autenticado', async () => {
  const quota = { plan: 'FREE', unlimited: false, limit: 3, used: 0, remaining: 3, resetAt: 'x', exhausted: false };
  let askedFor;
  getImpl = async (user) => {
    askedFor = user;
    return quota;
  };
  const res = fakeRes();
  await getChatQuotaController({ user: { userId: 1, role: 'USER' } }, res, () => assert.fail());

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, quota);
  assert.deepEqual(askedFor, { userId: 1, role: 'USER' });
});

test('los errores van a next', async () => {
  const boom = new Error('boom');
  getImpl = async () => {
    throw boom;
  };
  let received;
  await getChatQuotaController({ user: { userId: 1 } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, boom);
});
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd backend && node --experimental-test-module-mocks --test test/chat/chatQuota.controller.test.js`
Expected: FAIL con `Cannot find module .../chatQuota.controller.js`.

- [ ] **Step 3: Implementar**

`backend/src/modules/chat/chatQuota.controller.js`:

```js
import { successResponse } from '../../utils/response.js';
import { getChatQuota } from './chatQuota.service.js';

/** Cuota de hoy del Chef IA, sin consumir mensajes. */
export const getChatQuotaController = async (req, res, next) => {
  try {
    const quota = await getChatQuota(req.user);
    return successResponse(res, quota, 'Cuota del chat obtenida correctamente');
  } catch (error) {
    next(error);
  }
};
```

En `backend/src/modules/chat/chat.routes.js`, agregar el import después del import de `./chat.controller.js`:

```js
import { getChatQuotaController } from './chatQuota.controller.js';
```

y antes de `export default router`:

```js
/**
 * @openapi
 * /api/v1/chat/quota:
 *   get:
 *     tags: [Chat]
 *     summary: Mensajes del Chef IA que le quedan hoy al usuario
 *     description: >
 *       No consume mensajes. Para PRO y ADMIN unlimited es true y limit, used
 *       y remaining vienen null. data es null si Redis no está disponible.
 *       El día cambia a la medianoche de Bogotá (resetAt).
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cuota de hoy
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/quota', authenticateToken(['ADMIN', 'USER']), getChatQuotaController);
```

- [ ] **Step 4: Correr toda la suite del backend**

Run: `cd backend && npm test`
Expected: PASS, 0 fallos.

- [ ] **Step 5: Commit y push del backend**

```bash
git add backend/src/modules/chat/chatQuota.controller.js backend/src/modules/chat/chat.routes.js backend/test/chat/chatQuota.controller.test.js
git commit -m "feat(chat): endpoint GET /chat/quota"
git pull --rebase
git push origin main
```

**Nota de despliegue:** la app publicada en Play no conoce `CHAT_DAILY_LIMIT`. Cuando un usuario FREE con esa versión llegue a 3 mensajes, verá el texto del límite por minuto ("Espera un momento…"). Si el usuario no quiere eso hasta publicar la nueva versión, la salida es poner `CHAT_DAILY_LIMIT_FREE` alto (por ejemplo 1000) en Coolify y bajarlo a 3 al publicar. **Preguntarle antes del push cuál prefiere.**

---

### Task 6: App: modelo de cuota y repositorio

**Files:**
- Create: `nutrilife/lib/features/chatbot/data/models/chat_quota_model.dart`
- Modify: `nutrilife/lib/core/network/api_routes.dart` (después de `chatActiveSession`)
- Modify: `nutrilife/lib/features/chatbot/data/chat_repository.dart`
- Test: `nutrilife/test/features/chatbot/chat_quota_repository_test.dart`

**Interfaces:**
- Consumes: la forma `Quota` del backend; el 429 `{ error: { code }, data: { quota } }`; `GET /chat/quota`.
- Produces:
  - `class ChatQuota { bool unlimited; int? limit; int? used; int? remaining; DateTime? resetAt /* local */; bool exhausted; static ChatQuota? fromMap(Object? raw); }`
  - `class ChatQuotaExceededException implements Exception { ChatQuota quota; bool get isFairUse; }`
  - `ChatResponse.quota` (`ChatQuota?`, opcional en el constructor)
  - `ChatRepository.getQuota(): Future<ChatQuota?>`. Devuelve `null` si falla.
  - `ChatRepository.sendMessage` lanza `ChatQuotaExceededException` en un 429 con código `CHAT_DAILY_LIMIT` o `CHAT_FAIR_USE_LIMIT`.
  - `ApiRoutes.chatQuota = '/chat/quota'`

- [ ] **Step 1: Escribir el test que falla**

`nutrilife/test/features/chatbot/chat_quota_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Responde con el status y el body indicados y recuerda la ruta pedida.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, this.body);

  final int status;
  final Object body;
  String? lastPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatRepository _repo(_StatusAdapter adapter) => ChatRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter,
    );

const _freeQuota = {
  'plan': 'FREE',
  'unlimited': false,
  'limit': 3,
  'used': 1,
  'remaining': 2,
  'resetAt': '2026-10-18T05:00:00.000Z',
  'exhausted': false,
};

Map<String, Object?> _quotaError(String code, Map<String, Object?> quota) => {
      'success': false,
      'message': 'Usaste tus 3 mensajes de hoy con el Chef IA.',
      'error': {'code': code, 'details': []},
      'data': {'quota': quota},
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleState.instance.setPreference(LanguagePreference.es);
  });

  group('ChatQuota.fromMap', () {
    test('lee la cuota FREE', () {
      final quota = ChatQuota.fromMap(_freeQuota)!;
      expect(quota.unlimited, isFalse);
      expect(quota.limit, 3);
      expect(quota.used, 1);
      expect(quota.remaining, 2);
      expect(quota.exhausted, isFalse);
      expect(quota.resetAt, DateTime.utc(2026, 10, 18, 5).toLocal());
    });

    test('lee la cuota PRO sin números', () {
      final quota = ChatQuota.fromMap({
        'plan': 'PRO',
        'unlimited': true,
        'limit': null,
        'used': null,
        'remaining': null,
        'resetAt': '2026-10-18T05:00:00.000Z',
        'exhausted': false,
      })!;
      expect(quota.unlimited, isTrue);
      expect(quota.limit, isNull);
      expect(quota.remaining, isNull);
    });

    test('algo que no es un mapa es null', () {
      expect(ChatQuota.fromMap(null), isNull);
      expect(ChatQuota.fromMap('x'), isNull);
    });
  });

  test('la respuesta del chat trae la cuota', () async {
    final repo = _repo(_StatusAdapter(200, {
      'success': true,
      'data': {'type': 'CHAT', 'message': 'hola', 'recipe': null, 'quota': _freeQuota},
    }));

    final reply = await repo.sendMessage('hola');

    expect(reply.quota?.remaining, 2);
  });

  test('un 429 CHAT_DAILY_LIMIT es ChatQuotaExceededException', () async {
    final repo = _repo(_StatusAdapter(
      429,
      _quotaError('CHAT_DAILY_LIMIT', {..._freeQuota, 'used': 3, 'remaining': 0, 'exhausted': true}),
    ));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(isA<ChatQuotaExceededException>()
          .having((e) => e.quota.remaining, 'remaining', 0)
          .having((e) => e.isFairUse, 'isFairUse', isFalse)),
    );
  });

  test('un 429 CHAT_FAIR_USE_LIMIT es de uso justo', () async {
    final repo = _repo(_StatusAdapter(
      429,
      _quotaError('CHAT_FAIR_USE_LIMIT', {
        'plan': 'PRO',
        'unlimited': true,
        'limit': null,
        'used': null,
        'remaining': null,
        'resetAt': '2026-10-18T05:00:00.000Z',
        'exhausted': true,
      }),
    ));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(isA<ChatQuotaExceededException>().having((e) => e.isFairUse, 'isFairUse', isTrue)),
    );
  });

  test('el 429 por minuto no es de cuota', () async {
    final repo = _repo(_StatusAdapter(429, {
      'success': false,
      'message': 'Has superado el límite de solicitudes.',
      'error': {'code': 'RATE_LIMIT_EXCEEDED', 'details': []},
    }));

    await expectLater(
      repo.sendMessage('hola'),
      throwsA(predicate((e) => e is! ChatQuotaExceededException)),
    );
  });

  test('getQuota pide /chat/quota y la lee', () async {
    final adapter = _StatusAdapter(200, {'success': true, 'data': _freeQuota});

    final quota = await _repo(adapter).getQuota();

    expect(adapter.lastPath, '/chat/quota');
    expect(quota?.remaining, 2);
  });

  test('getQuota devuelve null si el backend falla', () async {
    final adapter = _StatusAdapter(500, {'success': false, 'message': 'x'});

    expect(await _repo(adapter).getQuota(), isNull);
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_quota_repository_test.dart`
Expected: FAIL de compilación: `chat_quota_model.dart` no existe.

- [ ] **Step 3: Crear el modelo**

`nutrilife/lib/features/chatbot/data/models/chat_quota_model.dart`:

```dart
/// Mensajes del Chef IA que le quedan hoy al usuario, según el backend.
///
/// Para PRO y ADMIN [unlimited] es true y [limit], [used] y [remaining] vienen
/// null: el tope de uso justo de PRO no se muestra.
class ChatQuota {
  final bool unlimited;
  final int? limit;
  final int? used;
  final int? remaining;

  /// Próxima medianoche de Bogotá, en la hora local del teléfono.
  final DateTime? resetAt;

  /// Sin mensajes por hoy: el chat se bloquea hasta [resetAt].
  final bool exhausted;

  const ChatQuota({
    required this.unlimited,
    this.limit,
    this.used,
    this.remaining,
    this.resetAt,
    this.exhausted = false,
  });

  /// Lee el mapa `quota` del backend. Si no es un mapa, devuelve null.
  static ChatQuota? fromMap(Object? raw) {
    if (raw is! Map) return null;
    int? asInt(Object? value) => value is num ? value.toInt() : null;
    final resetAt = raw['resetAt'];
    return ChatQuota(
      unlimited: raw['unlimited'] == true,
      limit: asInt(raw['limit']),
      used: asInt(raw['used']),
      remaining: asInt(raw['remaining']),
      resetAt: resetAt is String ? DateTime.tryParse(resetAt)?.toLocal() : null,
      exhausted: raw['exhausted'] == true,
    );
  }
}

/// El usuario usó sus mensajes del día (FREE) o llegó al tope de uso justo
/// (PRO). No confundir con RateLimitException, que es el límite por minuto.
class ChatQuotaExceededException implements Exception {
  final ChatQuota quota;

  const ChatQuotaExceededException(this.quota);

  bool get isFairUse => quota.unlimited;

  @override
  String toString() => 'ChatQuotaExceededException(fairUse: $isFairUse)';
}
```

- [ ] **Step 4: Ruta y repositorio**

En `nutrilife/lib/core/network/api_routes.dart`, después de `chatActiveSession`:

```dart
  static const String chatQuota = '/chat/quota';
```

En `nutrilife/lib/features/chatbot/data/chat_repository.dart`:

1. Import (junto a los otros `models/`):
```dart
import 'models/chat_quota_model.dart';
```
2. `ChatResponse` agrega el campo y el parámetro opcional:
```dart
  final ChatActions? actions;
  final ChatQuota? quota;

  const ChatResponse({
    required this.type,
    required this.text,
    this.recipe,
    this.actions,
    this.quota,
  });
```
3. En `sendMessage`, como primera línea dentro de `on DioException catch (e) {`:
```dart
      final quotaError = _quotaExceededFrom(e.response);
      if (quotaError != null) throw quotaError;
```
4. Método nuevo `getQuota`, debajo de `sendMessage`:
```dart
  /// Mensajes que le quedan hoy. Null si el backend no responde o no la sabe:
  /// el chat funciona igual, sin contador.
  Future<ChatQuota?> getQuota() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiRoutes.chatQuota);
      return ChatQuota.fromMap(response.data?['data']);
    } on DioException {
      return null;
    }
  }

  static const _quotaErrorCodes = {'CHAT_DAILY_LIMIT', 'CHAT_FAIR_USE_LIMIT'};

  /// El 429 del límite del día trae la cuota en `data.quota`. El del límite
  /// por minuto no, y sigue su camino de siempre.
  ChatQuotaExceededException? _quotaExceededFrom(Response? response) {
    if (response?.statusCode != 429) return null;
    final body = response?.data;
    if (body is! Map) return null;
    final code = (body['error'] as Map?)?['code'];
    if (!_quotaErrorCodes.contains(code)) return null;
    final quota = ChatQuota.fromMap((body['data'] as Map?)?['quota']) ??
        ChatQuota(
          unlimited: code == 'CHAT_FAIR_USE_LIMIT',
          remaining: 0,
          exhausted: true,
        );
    return ChatQuotaExceededException(quota);
  }
```
5. En `_parseEnvelope`, leer la cuota una vez al principio y pasarla a los dos `ChatResponse`:
```dart
    final quota = ChatQuota.fromMap(envelope['quota']);
```
y agregar `quota: quota,` en los dos `return ChatResponse(...)`.

- [ ] **Step 5: Correr los tests y ver que pasan**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_quota_repository_test.dart test/features/chatbot/chat_repository_test.dart`
Expected: PASS todos.

- [ ] **Step 6: Commit (local)**

```bash
git add nutrilife/lib/features/chatbot/data/models/chat_quota_model.dart nutrilife/lib/core/network/api_routes.dart nutrilife/lib/features/chatbot/data/chat_repository.dart nutrilife/test/features/chatbot/chat_quota_repository_test.dart
git commit -m "feat(chat): la app lee la cuota diaria del Chef IA"
```

---

### Task 7: App: textos y estado de la cuota en `ChatViewModel`

**Files:**
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb` (al final, antes de `}`)
- Regenerate: `nutrilife/lib/l10n/app_localizations*.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart`
- Test: `nutrilife/test/features/chatbot/chat_view_model_quota_test.dart`

**Interfaces:**
- Consumes: `ChatRepository.getQuota()`, `ChatResponse.quota` y `ChatQuotaExceededException` (Task 6).
- Produces:
  - `ChatViewModel.quota: ChatQuota?`, `ChatViewModel.isQuotaExhausted: bool` y `ChatViewModel.loadQuota(): Future<void>`
  - Claves l10n: `chatQuotaRemaining(int remaining, int limit)`, `chatQuotaExhaustedTitle(int limit)`, `chatQuotaFairUseTitle`, `chatQuotaResetsAt(String time)`, `chatQuotaGoPremium`, `chatQuotaReply`, `chatQuotaFairUseReply`

- [ ] **Step 1: Agregar los textos**

En `nutrilife/lib/l10n/app_es.arb`, agregar una coma al final de la última línea (`"progressHydrationCardTitle": "Vasos de agua · últimos 7 días"`) y después estas claves antes del `}` final:

```json
  "chatQuotaRemaining": "{remaining} de {limit} mensajes hoy",
  "@chatQuotaRemaining": {
    "placeholders": {
      "remaining": { "type": "int" },
      "limit": { "type": "int" }
    }
  },
  "chatQuotaExhaustedTitle": "{limit, plural, =1{Usaste tu mensaje de hoy} other{Usaste tus {limit} mensajes de hoy}}",
  "@chatQuotaExhaustedTitle": {
    "placeholders": {
      "limit": { "type": "int" }
    }
  },
  "chatQuotaFairUseTitle": "Llegaste al límite de uso justo de hoy",
  "chatQuotaResetsAt": "Se reinician a las {time}",
  "@chatQuotaResetsAt": {
    "placeholders": {
      "time": { "type": "String" }
    }
  },
  "chatQuotaGoPremium": "Hazte Premium",
  "chatQuotaReply": "Por hoy ya usaste tus mensajes conmigo. Vuelve mañana o hazte Premium para seguir cocinando juntos.",
  "chatQuotaFairUseReply": "Hoy hablamos muchísimo. Descansemos y seguimos mañana."
```

En `nutrilife/lib/l10n/app_en.arb`, agregar una coma al final de la última línea (`"progressHydrationCardTitle": "Glasses of water · last 7 days"`) y después:

```json
  "chatQuotaRemaining": "{remaining} of {limit} messages today",
  "chatQuotaExhaustedTitle": "{limit, plural, =1{You've used your message for today} other{You've used your {limit} messages for today}}",
  "chatQuotaFairUseTitle": "You've reached today's fair-use limit",
  "chatQuotaResetsAt": "They reset at {time}",
  "chatQuotaGoPremium": "Go Premium",
  "chatQuotaReply": "You've used your messages with me for today. Come back tomorrow or go Premium to keep cooking together.",
  "chatQuotaFairUseReply": "We talked a lot today. Let's rest and pick up tomorrow."
```

Run: `cd nutrilife && flutter gen-l10n && flutter test test/l10n/arb_keys_test.dart`
Expected: genera sin errores y el test pasa.

- [ ] **Step 2: Escribir el test que falla**

`nutrilife/test/features/chatbot/chat_view_model_quota_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoFalso extends ChatRepository {
  _RepoFalso() : super(dio: Dio());

  ChatQuota? quotaInicial;
  Object? errorAlEnviar;
  ChatResponse respuesta =
      const ChatResponse(type: ChatResponseType.chat, text: 'listo');

  @override
  Future<ChatQuota?> getQuota() async => quotaInicial;

  @override
  Future<ChatResponse> sendMessage(String message,
      {List<int> fridgeItemIds = const [], List<int> foodIds = const []}) async {
    if (errorAlEnviar != null) throw errorAlEnviar!;
    return respuesta;
  }
}

const _dosDeTres = ChatQuota(unlimited: false, limit: 3, used: 1, remaining: 2);
const _agotada =
    ChatQuota(unlimited: false, limit: 3, used: 3, remaining: 0, exhausted: true);
const _usoJusto = ChatQuota(unlimited: true, exhausted: true);

void main() {
  late _RepoFalso repo;
  late ChatViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleState.instance.setPreference(LanguagePreference.es);
    repo = _RepoFalso();
    vm = ChatViewModel(repository: repo);
  });

  tearDown(() => vm.dispose());

  test('loadQuota guarda la cuota del backend', () async {
    repo.quotaInicial = _dosDeTres;

    await vm.loadQuota();

    expect(vm.quota?.remaining, 2);
    expect(vm.isQuotaExhausted, isFalse);
  });

  test('sin cuota del backend no hay bloqueo', () async {
    await vm.loadQuota();

    expect(vm.quota, isNull);
    expect(vm.isQuotaExhausted, isFalse);
  });

  test('cada respuesta actualiza la cuota', () async {
    repo.respuesta = const ChatResponse(
      type: ChatResponseType.chat,
      text: 'listo',
      quota: _agotada,
    );

    await vm.sendMessage('hola');

    expect(vm.quota?.remaining, 0);
    expect(vm.isQuotaExhausted, isTrue);
  });

  test('el límite del día bloquea y el bot lo explica', () async {
    repo.errorAlEnviar = const ChatQuotaExceededException(_agotada);

    await vm.sendMessage('hola');

    expect(vm.isQuotaExhausted, isTrue);
    expect(vm.errorMessage, isNull);
    expect(vm.messages.last.isUser, isFalse);
    expect(vm.messages.last.text, startsWith('Por hoy ya usaste tus mensajes'));
  });

  test('el tope de uso justo usa su propio texto', () async {
    repo.errorAlEnviar = const ChatQuotaExceededException(_usoJusto);

    await vm.sendMessage('hola');

    expect(vm.isQuotaExhausted, isTrue);
    expect(vm.messages.last.text, startsWith('Hoy hablamos muchísimo'));
  });
}
```

Nota: el texto completo del bot está en `messages.last.text` aunque el efecto de escritura siga en curso. `displayedText` es lo que va apareciendo.

- [ ] **Step 3: Correr el test y ver que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_view_model_quota_test.dart`
Expected: FAIL de compilación: `loadQuota`, `quota` e `isQuotaExhausted` no existen.

- [ ] **Step 4: Implementar en el ViewModel**

En `nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart`:

1. Import:
```dart
import '../../data/models/chat_quota_model.dart';
```
2. Debajo de `int? _currentSessionId;`:
```dart
  ChatQuota? _quota;
```
3. Debajo del getter `currentSessionId`:
```dart
  /// Mensajes que le quedan hoy. Null si el backend no la ha dicho.
  ChatQuota? get quota => _quota;

  /// Sin mensajes por hoy: la pantalla cambia el input por la tarjeta.
  bool get isQuotaExhausted => _quota?.exhausted ?? false;

  /// Pide la cuota al abrir el chat. Si falla, el chat sigue sin contador.
  Future<void> loadQuota() async {
    try {
      final quota = await _repository.getQuota();
      if (quota == null) return;
      _quota = quota;
      notifyListeners();
    } catch (e) {
      debugPrint('ChatViewModel.loadQuota falló: $e');
    }
  }
```
4. En `sendMessage`, justo después de `final reply = await _repository.sendMessage(...);`:
```dart
      if (reply.quota != null) _quota = reply.quota;
```
5. En el `catch (e, stackTrace)`, antes del `if (e is RateLimitException)`:
```dart
      if (e is ChatQuotaExceededException) {
        _quota = e.quota;
        _startTypewriter(
          e.isFairUse ? currentL10n.chatQuotaFairUseReply : currentL10n.chatQuotaReply,
        );
        return;
      }
```
6. En el `finally`, cambiar la condición del `pulse` por:
```dart
      if (_errorMessage == null &&
          !DioClient.rateLimit.isExhausted &&
          !isQuotaExhausted) {
```

- [ ] **Step 5: Correr los tests y ver que pasan**

Run: `cd nutrilife && flutter test test/features/chatbot/`
Expected: PASS todos (los de cuota nuevos y los anteriores del chat).

- [ ] **Step 6: Commit (local)**

```bash
git add nutrilife/lib/l10n/app_es.arb nutrilife/lib/l10n/app_en.arb nutrilife/lib/l10n/app_localizations.dart nutrilife/lib/l10n/app_localizations_es.dart nutrilife/lib/l10n/app_localizations_en.dart nutrilife/lib/features/chatbot/presentation/controllers/chat_view_model.dart nutrilife/test/features/chatbot/chat_view_model_quota_test.dart
git commit -m "feat(chat): el chat guarda la cuota del día y avisa al agotarse"
```

---

### Task 8: App: contador, tarjeta de bloqueo y pantalla del chat

**Files:**
- Create: `nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_chip.dart`
- Create: `nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart` (imports, `initState`, `build` líneas ~208 y ~244-252)
- Test: `nutrilife/test/features/chatbot/chat_quota_widgets_test.dart`

**Interfaces:**
- Consumes: `ChatQuota` (Task 6); `ChatViewModel.quota`, `isQuotaExhausted` y `loadQuota()`, más las claves l10n (Task 7); `PremiumScreen` de `lib/features/premium/presentation/screens/premium_screen.dart`.
- Produces: `ChatQuotaChip({required ChatQuota? quota})` y `ChatQuotaBlockedCard({required ChatQuota quota, VoidCallback? onGoPremium})`. Con `onGoPremium` en null no aparece el botón.

- [ ] **Step 1: Escribir el test que falla**

`nutrilife/test/features/chatbot/chat_quota_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_quota_chip.dart';

import '../../helpers/l10n_app.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('es')}) =>
    l10nApp(Scaffold(body: Center(child: child)), locale: locale);

void main() {
  group('ChatQuotaChip', () {
    testWidgets('muestra cuántos mensajes quedan', (tester) async {
      await tester.pumpWidget(_wrap(const ChatQuotaChip(
        quota: ChatQuota(unlimited: false, limit: 3, used: 1, remaining: 2),
      )));

      expect(find.text('2 de 3 mensajes hoy'), findsOneWidget);
    });

    testWidgets('en inglés', (tester) async {
      await tester.pumpWidget(_wrap(
        const ChatQuotaChip(
          quota: ChatQuota(unlimited: false, limit: 3, used: 2, remaining: 1),
        ),
        locale: const Locale('en'),
      ));

      expect(find.text('1 of 3 messages today'), findsOneWidget);
    });

    testWidgets('PRO no ve el contador', (tester) async {
      await tester.pumpWidget(
          _wrap(const ChatQuotaChip(quota: ChatQuota(unlimited: true))));

      expect(find.byKey(const ValueKey('chat-quota-chip')), findsNothing);
    });

    testWidgets('sin cuota no hay contador', (tester) async {
      await tester.pumpWidget(_wrap(const ChatQuotaChip(quota: null)));

      expect(find.byKey(const ValueKey('chat-quota-chip')), findsNothing);
    });
  });

  group('ChatQuotaBlockedCard', () {
    final resetAt = DateTime(2026, 10, 18);

    testWidgets('FREE: título, hora de reinicio y botón a Premium',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(ChatQuotaBlockedCard(
        quota: ChatQuota(
          unlimited: false,
          limit: 3,
          used: 3,
          remaining: 0,
          resetAt: resetAt,
          exhausted: true,
        ),
        onGoPremium: () => taps++,
      )));

      expect(find.text('Usaste tus 3 mensajes de hoy'), findsOneWidget);
      expect(find.textContaining('Se reinician a las'), findsOneWidget);
      await tester.tap(find.text('Hazte Premium'));
      expect(taps, 1);
    });

    testWidgets('PRO en el tope: uso justo y sin botón', (tester) async {
      await tester.pumpWidget(_wrap(ChatQuotaBlockedCard(
        quota: ChatQuota(unlimited: true, resetAt: resetAt, exhausted: true),
      )));

      expect(find.text('Llegaste al límite de uso justo de hoy'), findsOneWidget);
      expect(find.text('Hazte Premium'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Correr el test y ver que falla**

Run: `cd nutrilife && flutter test test/features/chatbot/chat_quota_widgets_test.dart`
Expected: FAIL de compilación: los widgets no existen.

- [ ] **Step 3: Crear el contador**

`nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_chip.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../data/models/chat_quota_model.dart';

/// "2 de 3 mensajes hoy". Solo para FREE: PRO y ADMIN no lo ven.
class ChatQuotaChip extends StatelessWidget {
  final ChatQuota? quota;

  const ChatQuotaChip({super.key, required this.quota});

  @override
  Widget build(BuildContext context) {
    final q = quota;
    final limit = q?.limit;
    final remaining = q?.remaining;
    if (q == null || q.unlimited || limit == null || remaining == null) {
      return const SizedBox.shrink();
    }

    // Ámbar cuando queda el último y rojo cuando no queda ninguno.
    final (bg, fg) = remaining <= 0
        ? (const Color(0xFFFEE2E2), const Color(0xFFB91C1C))
        : remaining == 1
            ? (const Color(0xFFFFFBEB), const Color(0xFF92400E))
            : (const Color(0xFFF1F5F9), const Color(0xFF475569));

    return Container(
      key: const ValueKey('chat-quota-chip'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            context.l10n.chatQuotaRemaining(remaining, limit),
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Crear la tarjeta de bloqueo**

`nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_quota_model.dart';

/// Va en lugar del input cuando ya no quedan mensajes por hoy.
/// Sin [onGoPremium] (usuarios PRO) no aparece el botón.
class ChatQuotaBlockedCard extends StatelessWidget {
  final ChatQuota quota;
  final VoidCallback? onGoPremium;

  const ChatQuotaBlockedCard({
    super.key,
    required this.quota,
    this.onGoPremium,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resetAt = quota.resetAt;
    final title = quota.unlimited
        ? l10n.chatQuotaFairUseTitle
        : l10n.chatQuotaExhaustedTitle(quota.limit ?? 0);

    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('chat-quota-blocked'),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/nutria_atenta.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (resetAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.chatQuotaResetsAt(
                        TimeOfDay.fromDateTime(resetAt).format(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (onGoPremium != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: onGoPremium,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryStart,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: Text(l10n.chatQuotaGoPremium),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Conectar en la pantalla del chat**

En `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart`:

1. Imports:
```dart
import '../../../premium/presentation/screens/premium_screen.dart';
import '../widgets/chat_quota_blocked_card.dart';
import '../widgets/chat_quota_chip.dart';
```
2. En `initState`, después de la línea de `loadActiveSession`:
```dart
    unawaited(_viewModel.loadQuota());
```
3. Método nuevo en `_AiChatViewState`, junto a los otros handlers:
```dart
  void _openPremium() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
  }
```
4. En `build`, justo debajo de `const RateLimitChip(),`:
```dart
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => ChatQuotaChip(quota: _viewModel.quota),
        ),
```
5. Reemplazar el último `ListenableBuilder` (el que construye `ChatInputField`) por:
```dart
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final quota = _viewModel.quota;
            if (_viewModel.isQuotaExhausted && quota != null) {
              return ChatQuotaBlockedCard(
                quota: quota,
                onGoPremium: quota.unlimited ? null : _openPremium,
              );
            }
            return ChatInputField(
              onSend: _handleSend,
              isLoading: _viewModel.isLoading,
            );
          },
        ),
```

- [ ] **Step 6: Correr tests y análisis**

Run: `cd nutrilife && flutter test test/features/chatbot/ && flutter analyze lib/features/chatbot lib/core/network`
Expected: tests en PASS y `No issues found!`.

- [ ] **Step 7: Commit (local)**

```bash
git add nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_chip.dart nutrilife/lib/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart nutrilife/test/features/chatbot/chat_quota_widgets_test.dart
git commit -m "feat(chat): contador de mensajes y tarjeta para pasar a Premium"
```

---

### Task 9: Verificación final

**Files:** ninguno nuevo.

- [ ] **Step 1: Suites completas**

Run: `cd backend && npm test`
Expected: 0 fallos.

Run: `cd nutrilife && flutter test && flutter analyze`
Expected: todos los tests en PASS y `No issues found!` (o solo los avisos que ya existían antes de este plan; compáralos con `git stash` si hace falta).

- [ ] **Step 2: Diseño en inglés a 375 px**

Run: `cd nutrilife && flutter test test/l10n/english_layout_test.dart`
Expected: PASS. Si el test recorre pantallas, revisar que la tarjeta y el chip no se desborden en inglés.

- [ ] **Step 3: Abrir la app en el emulador**

La app apunta al backend de producción (`ApiBaseUrl`), así que el backend de la Tarea 5 tiene que estar desplegado. Abrir la app en el emulador de Android y dejar que el usuario pruebe:
- Una cuenta FREE ve "3 de 3 mensajes hoy". Después de 3 mensajes, aparece la tarjeta con "Hazte Premium" y el botón abre la pantalla Premium.
- Al pasar esa cuenta a PRO desde el admin y volver a abrir el chat, el contador desaparece.

No pushear la app sin que el usuario lo pida.
