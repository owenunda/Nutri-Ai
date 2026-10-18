# Suscripciones PRO con RevenueCat — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cobrar el PRO mensual y anual desde la app (Android + iOS) con RevenueCat y que el backend ajuste `users.plan` solo, conviviendo con el PRO regalado desde el panel.

**Architecture:** El backend guarda el regalo (`users.gift_pro*`) y la suscripción de tienda (`store_subscriptions`) por separado, y una función pura calcula el plan efectivo (`users.plan_id` / `pro_until`). Un webhook de RevenueCat y un `POST /subscription/sync` de la app hacen el mismo "sync": leen el estado real en la API de RevenueCat y recalculan. La app usa `purchases_flutter` detrás de un `PurchaseService` y conserva su pantalla premium.

**Tech Stack:** Node 22+ / Express / pg / axios / `node --test` (backend); React + Vite + TS (admin-panel); Flutter + Dio + `purchases_flutter` + ARB (app).

**Spec:** `docs/superpowers/specs/2026-10-17-suscripciones-revenuecat-design.md`

## Global Constraints

- Entitlement: `nutrilife_pro`. Paquetes del offering `current`: mensual y anual (productos `monthly` / `yearly` en la Test Store). Sin prueba gratis.
- Margen de la tienda al calcular `pro_until`: **1 hora**.
- Variables de entorno del backend: `REVENUECAT_SECRET_KEY`, `REVENUECAT_WEBHOOK_AUTH`, `REVENUECAT_ALLOW_SANDBOX` (solo `true` lo activa).
- Keys de la app solo por `--dart-define`: `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`. Nunca escritas en el código. Una build de producción nunca lleva la key `test_…`.
- `purchases_flutter` solo se importa en `nutrilife/lib/core/services/purchase_service.dart`.
- Textos del usuario: app por ARB (`app_es.arb` es la plantilla, también `app_en.arb`, luego `flutter gen-l10n`); backend por `src/i18n/messages.js` (el mensaje del `AppError` en español, la versión en inglés en `CODE_MESSAGES.en`).
- Commits sin línea `Co-Authored-By` de Claude (preferencia del usuario).
- Backend: `git pull` antes de commitear; los commits del backend se pueden pushear a `main` sin preguntar. Los de la app y el panel se commitean pero **se pregunta antes de pushear**.
- Pruebas del backend: `cd backend && npm test` (o un archivo: `node --experimental-test-module-mocks --test test/ruta/archivo.test.js`). Pruebas de la app: `cd nutrilife && flutter test`.

---

## Mapa de archivos

**Backend (`backend/`)**
- Create `src/database/backups/update_17_10_2026_store_subscriptions.sql` — columnas del regalo, tabla `store_subscriptions`, copia de los PRO actuales.
- Create `src/modules/subscription/effectivePlan.js` — regla pura del plan efectivo.
- Create `src/modules/subscription/subscriberState.js` — lee la respuesta de RevenueCat y la convierte en la fila de `store_subscriptions`.
- Create `src/modules/subscription/revenuecat.client.js` — `GET /v1/subscribers/{id}`.
- Create `src/modules/subscription/subscription.repository.js` — SQL del módulo y transacción.
- Create `src/modules/subscription/subscription.service.js` — `syncUser`, `saveGift`, `handleWebhookEvent`.
- Create `src/modules/subscription/webhookAuth.middleware.js` — valida el header del webhook.
- Create `src/modules/subscription/subscription.controller.js`, `subscription.routes.js`.
- Modify `src/config/env_config.js` — bloque `revenuecat` y `rateLimit.subscriptionSyncPerMinute`.
- Modify `src/middleware/rateLimit.middleware.js` — `subscriptionSyncRateLimit`.
- Modify `src/middleware/activityLogger.middleware.js` — ignora el webhook.
- Modify `src/i18n/messages.js` — `SUBSCRIPTION_PROVIDER_ERROR`.
- Modify `src/app.js` — monta `/api/v1/subscription`.
- Modify `src/modules/admin/admin.service.js`, `admin.repository.js` — el panel cambia el regalo; detalle con `proSource` y suscripción.
- Modify `src/modules/user/user.repository.js`, `user.service.js` — `proSource` en el perfil.
- Tests: `test/subscription/*.test.js`, ajustes en `test/admin/admin.service.test.js`, `test/user/user.service.test.js`.

**Admin panel (`admin-panel/`)**
- Modify `src/types/admin.ts`, `src/pages/UserDetail.tsx`.

**App (`nutrilife/`)**
- Create `lib/core/services/purchase_service.dart` — interfaz + implementación RevenueCat.
- Create `lib/features/premium/data/subscription_repository.dart` — `POST /subscription/sync`.
- Create `test/helpers/fake_purchase_service.dart`.
- Modify `pubspec.yaml`, `lib/main.dart`, `lib/core/services/session_service.dart`, `lib/core/network/api_routes.dart`.
- Modify `lib/features/premium/presentation/screens/premium_screen.dart`.
- Modify `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/presentation/screens/profile_screen.dart`.
- Modify `lib/features/chatbot/presentation/screens/ai_chat_view.dart`.
- Modify `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` (+ generados).
- Tests: `test/features/premium/premium_screen_test.dart`, `test/features/premium/subscription_repository_test.dart`, `test/features/profile/profile_pro_test.dart`, `test/core/services/purchase_offer_test.dart`.

---

### Task 1: Migración y regla del plan efectivo

**Files:**
- Create: `backend/src/database/backups/update_17_10_2026_store_subscriptions.sql`
- Create: `backend/src/modules/subscription/effectivePlan.js`
- Test: `backend/test/subscription/effectivePlan.test.js`

**Interfaces:**
- Produces: `computeEffectivePlan({ giftPro, giftProUntil, storeExpiresAt }, now = new Date())` → `{ plan: 'FREE'|'PRO', proUntil: Date|null, proSource: 'gift'|'store'|'both'|null }`. `STORE_GRACE_MS = 3_600_000`.
- Produces (base): columnas `users.gift_pro`, `users.gift_pro_until`; tabla `store_subscriptions(user_id, product_id, store, expires_at, will_renew, billing_issue, environment, updated_at)`.

- [ ] **Step 1: Escribir la migración**

`backend/src/database/backups/update_17_10_2026_store_subscriptions.sql`:

```sql
-- Suscripciones de tienda (RevenueCat) y PRO regalado por separado
-- (spec 2026-10-17, suscripciones PRO con RevenueCat).
--
-- users.plan_id / users.pro_until pasan a ser el plan efectivo, calculado por
-- el backend a partir de:
--   gift_pro / gift_pro_until: el PRO regalado desde el panel. Con gift_pro,
--     gift_pro_until NULL = regalo sin vencimiento.
--   store_subscriptions: el estado del entitlement nutrilife_pro en RevenueCat.

ALTER TABLE users ADD COLUMN IF NOT EXISTS gift_pro BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gift_pro_until TIMESTAMPTZ;

-- Todo PRO de hoy es regalado: se copia al regalo para que nadie lo pierda.
UPDATE users u
   SET gift_pro = TRUE,
       gift_pro_until = u.pro_until
  FROM plans p
 WHERE p.plan_id = u.plan_id
   AND p.name = 'PRO'
   AND u.gift_pro = FALSE;

CREATE TABLE IF NOT EXISTS store_subscriptions (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    product_id TEXT,
    store TEXT,
    expires_at TIMESTAMPTZ,
    will_renew BOOLEAN NOT NULL DEFAULT FALSE,
    billing_issue BOOLEAN NOT NULL DEFAULT FALSE,
    environment TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

- [ ] **Step 2: Escribir las pruebas de la regla**

`backend/test/subscription/effectivePlan.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { computeEffectivePlan, STORE_GRACE_MS } = await import(src('modules/subscription/effectivePlan.js'));

const NOW = new Date('2026-10-17T15:00:00Z');
const at = (iso) => new Date(iso);
const iso = (date) => date?.toISOString() ?? null;
const run = (inputs) => {
  const result = computeEffectivePlan({ giftPro: false, giftProUntil: null, storeExpiresAt: null, ...inputs }, NOW);
  return { ...result, proUntil: iso(result.proUntil) };
};

test('el margen de la tienda es 1 hora', () => {
  assert.equal(STORE_GRACE_MS, 60 * 60 * 1000);
});

test('sin regalo ni tienda es FREE', () => {
  assert.deepEqual(run({}), { plan: 'FREE', proUntil: null, proSource: null });
});

test('regalo con fecha vigente', () => {
  assert.deepEqual(run({ giftPro: true, giftProUntil: at('2026-11-01T00:00:00Z') }), {
    plan: 'PRO',
    proUntil: '2026-11-01T00:00:00.000Z',
    proSource: 'gift',
  });
});

test('regalo sin vencimiento', () => {
  assert.deepEqual(run({ giftPro: true }), { plan: 'PRO', proUntil: null, proSource: 'gift' });
});

test('regalo vencido no cuenta', () => {
  assert.deepEqual(run({ giftPro: true, giftProUntil: at('2026-10-01T00:00:00Z') }), {
    plan: 'FREE',
    proUntil: null,
    proSource: null,
  });
});

test('gift_pro_until sin gift_pro no cuenta', () => {
  assert.equal(run({ giftPro: false, giftProUntil: at('2026-11-01T00:00:00Z') }).plan, 'FREE');
});

test('solo tienda: vence una hora después de la tienda', () => {
  assert.deepEqual(run({ storeExpiresAt: at('2026-11-17T15:00:00Z') }), {
    plan: 'PRO',
    proUntil: '2026-11-17T16:00:00.000Z',
    proSource: 'store',
  });
});

test('tienda vencida hace menos de una hora sigue PRO', () => {
  assert.equal(run({ storeExpiresAt: at('2026-10-17T14:30:00Z') }).plan, 'PRO');
});

test('tienda vencida hace más de una hora es FREE', () => {
  assert.equal(run({ storeExpiresAt: at('2026-10-17T13:59:00Z') }).plan, 'FREE');
});

test('regalo y tienda: gana la fecha más lejana', () => {
  assert.deepEqual(
    run({ giftPro: true, giftProUntil: at('2026-12-01T00:00:00Z'), storeExpiresAt: at('2026-11-17T15:00:00Z') }),
    { plan: 'PRO', proUntil: '2026-12-01T00:00:00.000Z', proSource: 'both' }
  );
  assert.equal(
    run({ giftPro: true, giftProUntil: at('2026-10-20T00:00:00Z'), storeExpiresAt: at('2026-11-17T15:00:00Z') }).proUntil,
    '2026-11-17T16:00:00.000Z'
  );
});

test('regalo sin vencimiento y tienda: sin vencimiento', () => {
  assert.deepEqual(run({ giftPro: true, storeExpiresAt: at('2026-11-17T15:00:00Z') }), {
    plan: 'PRO',
    proUntil: null,
    proSource: 'both',
  });
});

test('acepta fechas como texto (pg puede devolver strings)', () => {
  assert.equal(run({ storeExpiresAt: '2026-11-17T15:00:00Z' }).proUntil, '2026-11-17T16:00:00.000Z');
});
```

- [ ] **Step 3: Correr y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/effectivePlan.test.js`
Expected: FAIL (no existe `effectivePlan.js`).

- [ ] **Step 4: Implementar la regla**

`backend/src/modules/subscription/effectivePlan.js`:

```js
// Plan efectivo de un usuario a partir del PRO regalado y de la suscripción de
// tienda. Es la única regla: la usan el webhook, el sync, el panel y el perfil.

// Si la tienda renueva y el webhook llega tarde, el job de vencimiento no debe
// pasar al usuario a FREE unos minutos.
export const STORE_GRACE_MS = 60 * 60 * 1000;

const toDate = (value) => (value ? new Date(value) : null);

/**
 * @param {{giftPro: boolean, giftProUntil: Date|string|null, storeExpiresAt: Date|string|null}} inputs
 * @returns {{plan: 'FREE'|'PRO', proUntil: Date|null, proSource: 'gift'|'store'|'both'|null}}
 *   proUntil null con PRO = sin vencimiento.
 */
export const computeEffectivePlan = ({ giftPro, giftProUntil, storeExpiresAt }, now = new Date()) => {
  const giftEnd = toDate(giftProUntil);
  const giftActive = Boolean(giftPro) && (giftEnd === null || giftEnd > now);

  const storeExpiry = toDate(storeExpiresAt);
  const storeEnd = storeExpiry ? new Date(storeExpiry.getTime() + STORE_GRACE_MS) : null;
  const storeActive = storeEnd !== null && storeEnd > now;

  if (!giftActive && !storeActive) return { plan: 'FREE', proUntil: null, proSource: null };

  const proSource = giftActive && storeActive ? 'both' : giftActive ? 'gift' : 'store';
  if (giftActive && giftEnd === null) return { plan: 'PRO', proUntil: null, proSource };

  const ends = [giftActive ? giftEnd : null, storeActive ? storeEnd : null].filter(Boolean);
  return { plan: 'PRO', proUntil: new Date(Math.max(...ends.map((d) => d.getTime()))), proSource };
};
```

- [ ] **Step 5: Correr y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/effectivePlan.test.js`
Expected: PASS (12 pruebas).

- [ ] **Step 6: Commit**

```bash
git pull
git add backend/src/database/backups/update_17_10_2026_store_subscriptions.sql backend/src/modules/subscription/effectivePlan.js backend/test/subscription/effectivePlan.test.js
git commit -m "feat(suscripcion): migración y regla del plan efectivo"
```

---

### Task 2: Lectura de RevenueCat y cliente HTTP

**Files:**
- Create: `backend/src/modules/subscription/subscriberState.js`
- Create: `backend/src/modules/subscription/revenuecat.client.js`
- Modify: `backend/src/config/env_config.js`
- Modify: `backend/src/i18n/messages.js`
- Test: `backend/test/subscription/subscriberState.test.js`

**Interfaces:**
- Produces: `ENTITLEMENT_ID = 'nutrilife_pro'`; `readStoreSubscription(subscriber, { allowSandbox })` → `{ productId, store, expiresAt: Date|null, willRenew, billingIssue, environment: 'sandbox'|'production'|null }`.
- Produces: `fetchSubscriber(appUserId: string)` → objeto `subscriber` de RevenueCat; lanza `AppError(502, 'SUBSCRIPTION_PROVIDER_ERROR')` si falla o falta la key.
- Produces: `config.revenuecat = { secretKey, webhookAuth, allowSandbox }`, `config.rateLimit.subscriptionSyncPerMinute`.

- [ ] **Step 1: Escribir las pruebas de la lectura**

`backend/test/subscription/subscriberState.test.js`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { ENTITLEMENT_ID, readStoreSubscription } = await import(src('modules/subscription/subscriberState.js'));

const iso = (date) => date?.toISOString() ?? null;
const subscriber = ({ entitlement = {}, subscription = {}, productKey = 'monthly' } = {}) => ({
  entitlements: {
    nutrilife_pro: {
      expires_date: '2026-11-17T15:00:00Z',
      grace_period_expires_date: null,
      product_identifier: 'monthly',
      ...entitlement,
    },
  },
  subscriptions: {
    [productKey]: {
      store: 'test_store',
      is_sandbox: false,
      unsubscribe_detected_at: null,
      billing_issues_detected_at: null,
      ...subscription,
    },
  },
});
const read = (sub, allowSandbox = true) => {
  const state = readStoreSubscription(sub, { allowSandbox });
  return { ...state, expiresAt: iso(state.expiresAt) };
};

test('el entitlement es nutrilife_pro', () => {
  assert.equal(ENTITLEMENT_ID, 'nutrilife_pro');
});

test('suscripción activa', () => {
  assert.deepEqual(read(subscriber()), {
    productId: 'monthly',
    store: 'test_store',
    expiresAt: '2026-11-17T15:00:00.000Z',
    willRenew: true,
    billingIssue: false,
    environment: 'production',
  });
});

test('sin el entitlement queda vacía', () => {
  assert.deepEqual(read({ entitlements: {}, subscriptions: {} }), {
    productId: null,
    store: null,
    expiresAt: null,
    willRenew: false,
    billingIssue: false,
    environment: null,
  });
  assert.equal(read(undefined).expiresAt, null);
});

test('un entitlement vencido conserva su fecha (la regla decide)', () => {
  assert.equal(read(subscriber({ entitlement: { expires_date: '2026-09-01T00:00:00Z' } })).expiresAt, '2026-09-01T00:00:00.000Z');
});

test('el período de gracia alarga el vencimiento', () => {
  const state = read(subscriber({ entitlement: { grace_period_expires_date: '2026-11-24T15:00:00Z' } }));
  assert.equal(state.expiresAt, '2026-11-24T15:00:00.000Z');
});

test('renovación cancelada y problema de cobro', () => {
  const state = read(
    subscriber({
      subscription: { unsubscribe_detected_at: '2026-10-20T00:00:00Z', billing_issues_detected_at: '2026-10-21T00:00:00Z' },
    })
  );
  assert.equal(state.willRenew, false);
  assert.equal(state.billingIssue, true);
});

test('sandbox permitido cuenta', () => {
  const state = read(subscriber({ subscription: { is_sandbox: true } }), true);
  assert.equal(state.environment, 'sandbox');
  assert.equal(state.expiresAt, '2026-11-17T15:00:00.000Z');
});

test('sandbox no permitido no da PRO', () => {
  const state = read(subscriber({ subscription: { is_sandbox: true } }), false);
  assert.equal(state.environment, 'sandbox');
  assert.equal(state.expiresAt, null);
});

test('Play: encuentra la suscripción por el id base si la clave lleva el plan base', () => {
  const state = read(
    subscriber({ entitlement: { product_identifier: 'nutrilife_pro:monthly' }, productKey: 'nutrilife_pro', subscription: { store: 'play_store' } })
  );
  assert.equal(state.store, 'play_store');
  assert.equal(state.productId, 'nutrilife_pro:monthly');
});
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/subscriberState.test.js`
Expected: FAIL (no existe `subscriberState.js`).

- [ ] **Step 3: Implementar la lectura**

`backend/src/modules/subscription/subscriberState.js`:

```js
// Convierte la respuesta de GET /v1/subscribers/{id} de RevenueCat en la fila
// de store_subscriptions.

export const ENTITLEMENT_ID = 'nutrilife_pro';

const EMPTY = Object.freeze({
  productId: null,
  store: null,
  expiresAt: null,
  willRenew: false,
  billingIssue: false,
  environment: null,
});

const toDate = (value) => (value ? new Date(value) : null);
const later = (a, b) => (!a ? b : !b ? a : a > b ? a : b);

// En Play el producto puede venir como "suscripcion:plan_base" y la clave de
// subscriptions solo con la suscripción, o al revés.
const findSubscription = (subscriptions = {}, productId) => {
  if (!productId) return {};
  if (subscriptions[productId]) return subscriptions[productId];
  const base = productId.split(':')[0];
  const key = Object.keys(subscriptions).find((k) => k.split(':')[0] === base);
  return key ? subscriptions[key] : {};
};

/**
 * @param {Object|undefined} subscriber `subscriber` de la respuesta de RevenueCat.
 * @param {{allowSandbox: boolean}} options
 */
export const readStoreSubscription = (subscriber, { allowSandbox }) => {
  const entitlement = subscriber?.entitlements?.[ENTITLEMENT_ID];
  if (!entitlement) return { ...EMPTY };

  const productId = entitlement.product_identifier ?? null;
  const subscription = findSubscription(subscriber.subscriptions, productId);
  const sandbox = subscription.is_sandbox === true;
  const state = {
    productId,
    store: subscription.store ?? null,
    willRenew: !subscription.unsubscribe_detected_at,
    billingIssue: Boolean(subscription.billing_issues_detected_at),
    environment: sandbox ? 'sandbox' : 'production',
  };

  if (sandbox && !allowSandbox) return { ...state, expiresAt: null };
  return {
    ...state,
    expiresAt: later(toDate(entitlement.expires_date), toDate(entitlement.grace_period_expires_date)),
  };
};
```

- [ ] **Step 4: Correr y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/subscriberState.test.js`
Expected: PASS (9 pruebas).

- [ ] **Step 5: Config, mensaje y cliente HTTP**

En `backend/src/config/env_config.js`, dentro de `rateLimit` agregar:

```js
    subscriptionSyncPerMinute: Number(trim(env.RATE_LIMIT_SUBSCRIPTION_SYNC_PER_MINUTE)) || 10,
```

y después del bloque `chatQuota`:

```js
  revenuecat: {
    secretKey: trim(env.REVENUECAT_SECRET_KEY),
    webhookAuth: trim(env.REVENUECAT_WEBHOOK_AUTH),
    // Solo mientras se prueba con la Test Store o con testers de las tiendas.
    allowSandbox: trim(env.REVENUECAT_ALLOW_SANDBOX) === 'true',
  },
```

En `backend/src/i18n/messages.js`, dentro de `CODE_MESSAGES.en`, después del bloque `// Admin`, agregar:

```js
    // Suscripciones
    SUBSCRIPTION_PROVIDER_ERROR: 'We could not confirm your subscription. Try again in a few minutes.',
```

`backend/src/modules/subscription/revenuecat.client.js`:

```js
import axios from 'axios';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const BASE_URL = 'https://api.revenuecat.com/v1';

const providerError = () =>
  new AppError(
    'No pudimos confirmar tu suscripción. Intenta de nuevo en unos minutos.',
    502,
    'SUBSCRIPTION_PROVIDER_ERROR'
  );

/**
 * Estado de un usuario en RevenueCat. El app user id es nuestro user_id.
 * @returns {Promise<Object>} el `subscriber` de la respuesta.
 */
export const fetchSubscriber = async (appUserId) => {
  const { secretKey } = config.revenuecat;
  if (!secretKey) {
    console.error('[revenuecat] falta REVENUECAT_SECRET_KEY');
    throw providerError();
  }
  try {
    const { data } = await axios.get(`${BASE_URL}/subscribers/${encodeURIComponent(appUserId)}`, {
      headers: { Authorization: `Bearer ${secretKey}` },
      timeout: 10_000,
    });
    return data?.subscriber;
  } catch (error) {
    console.error('[revenuecat] no se pudo leer el suscriptor:', error.response?.status ?? '', error.message);
    throw providerError();
  }
};
```

- [ ] **Step 6: Correr toda la suite del backend**

Run: `cd backend && npm test`
Expected: PASS (nada existente se rompe).

- [ ] **Step 7: Commit**

```bash
git add backend/src/modules/subscription/subscriberState.js backend/src/modules/subscription/revenuecat.client.js backend/src/config/env_config.js backend/src/i18n/messages.js backend/test/subscription/subscriberState.test.js
git commit -m "feat(suscripcion): lectura del suscriptor de RevenueCat"
```

---

### Task 3: Repositorio y servicio del sync

**Files:**
- Create: `backend/src/modules/subscription/subscription.repository.js`
- Create: `backend/src/modules/subscription/subscription.service.js`
- Test: `backend/test/subscription/subscription.service.test.js`

**Interfaces:**
- Consumes: `computeEffectivePlan` (Task 1), `readStoreSubscription`, `fetchSubscriber`, `config.revenuecat.allowSandbox` (Task 2).
- Produces (repository): `inTransaction(fn)`, `lockPlanInputs(client, userId)` → `{ plan, giftPro, giftProUntil, storeExpiresAt } | null`, `upsertStoreSubscription(client, userId, state)`, `setGift(client, userId, { giftPro, giftProUntil })`, `setEffectivePlan(client, userId, { plan, proUntil })` → `{ userId, plan, proUntil }`, `findExistingUserIds(ids: number[])` → `number[]`.
- Produces (service): `syncUser(userId, now?)` → `{ plan, proUntil, proSource }`; `saveGift(userId, giftFor, now?)` → `{ userId, plan, proUntil, proSource } | null`, donde `giftFor(inputs)` devuelve `{ giftPro, giftProUntil }`; `webhookUserIds(event)` → `number[]`; `handleWebhookEvent(event)` → `{ synced: number[] }`.

- [ ] **Step 1: Escribir el repositorio**

`backend/src/modules/subscription/subscription.repository.js`:

```js
import pool from '../../database/connection.js';

/** Corre fn(client) dentro de una transacción. */
export const inTransaction = async (fn) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Lo que necesita la regla del plan, bloqueando la fila del usuario hasta el
 * fin de la transacción.
 * @returns {Promise<{plan: string, giftPro: boolean, giftProUntil: Date|null, storeExpiresAt: Date|null}|null>}
 */
export const lockPlanInputs = async (client, userId) => {
  const { rows } = await client.query(
    `SELECT p.name AS plan,
            u.gift_pro AS "giftPro",
            u.gift_pro_until AS "giftProUntil",
            ss.expires_at AS "storeExpiresAt"
       FROM users u
       INNER JOIN plans p ON p.plan_id = u.plan_id
       LEFT JOIN store_subscriptions ss ON ss.user_id = u.user_id
      WHERE u.user_id = $1
      FOR UPDATE OF u`,
    [userId]
  );
  return rows[0] ?? null;
};

export const upsertStoreSubscription = async (client, userId, state) => {
  await client.query(
    `INSERT INTO store_subscriptions
       (user_id, product_id, store, expires_at, will_renew, billing_issue, environment, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id) DO UPDATE SET
       product_id = EXCLUDED.product_id,
       store = EXCLUDED.store,
       expires_at = EXCLUDED.expires_at,
       will_renew = EXCLUDED.will_renew,
       billing_issue = EXCLUDED.billing_issue,
       environment = EXCLUDED.environment,
       updated_at = CURRENT_TIMESTAMP`,
    [userId, state.productId, state.store, state.expiresAt, state.willRenew, state.billingIssue, state.environment]
  );
};

export const setGift = async (client, userId, { giftPro, giftProUntil }) => {
  await client.query(
    `UPDATE users SET gift_pro = $2, gift_pro_until = $3, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1`,
    [userId, giftPro, giftProUntil]
  );
};

/** @returns {Promise<{userId: number, plan: string, proUntil: Date|null}>} */
export const setEffectivePlan = async (client, userId, { plan, proUntil }) => {
  const { rows } = await client.query(
    `UPDATE users u
        SET plan_id = p.plan_id, pro_until = $3, updated_at = CURRENT_TIMESTAMP
       FROM plans p
      WHERE u.user_id = $1 AND p.name = $2
      RETURNING u.user_id AS "userId", p.name AS plan, u.pro_until AS "proUntil"`,
    [userId, plan, proUntil]
  );
  return rows[0];
};

/** De una lista de ids, los que existen en users. */
export const findExistingUserIds = async (ids) => {
  const { rows } = await pool.query('SELECT user_id AS "userId" FROM users WHERE user_id = ANY($1::int[])', [ids]);
  return rows.map((row) => row.userId);
};
```

- [ ] **Step 2: Escribir las pruebas del servicio**

`backend/test/subscription/subscription.service.test.js`:

```js
import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { AppError } = await import(src('utils/AppError.js'));

const REPO_EXPORTS = [
  'findExistingUserIds',
  'inTransaction',
  'lockPlanInputs',
  'setEffectivePlan',
  'setGift',
  'upsertStoreSubscription',
];
const repo = {};
let subscriberImpl;
const settings = { allowSandbox: true };

mock.module(src('modules/subscription/subscription.repository.js'), {
  exports: Object.fromEntries(REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])),
});
mock.module(src('modules/subscription/revenuecat.client.js'), {
  exports: { fetchSubscriber: (...args) => subscriberImpl(...args) },
});
mock.module(src('config/env_config.js'), {
  exports: { config: { revenuecat: settings } },
});

const { handleWebhookEvent, saveGift, syncUser, webhookUserIds } = await import(
  src('modules/subscription/subscription.service.js')
);

const NOW = new Date('2026-10-17T15:00:00Z');
const CLIENT = { fake: 'client' };
let calls;

const activeSubscriber = (expires = '2026-11-17T15:00:00Z', sandbox = false) => ({
  entitlements: { nutrilife_pro: { expires_date: expires, product_identifier: 'monthly' } },
  subscriptions: { monthly: { store: 'test_store', is_sandbox: sandbox } },
});

beforeEach(() => {
  calls = [];
  settings.allowSandbox = true;
  repo.inTransaction = async (fn) => fn(CLIENT);
  repo.lockPlanInputs = async () => ({ plan: 'FREE', giftPro: false, giftProUntil: null, storeExpiresAt: null });
  repo.upsertStoreSubscription = async (client, userId, state) => calls.push(['upsert', userId, state]);
  repo.setGift = async (client, userId, gift) => calls.push(['gift', userId, gift]);
  repo.setEffectivePlan = async (client, userId, { plan, proUntil }) => {
    calls.push(['plan', userId, plan, proUntil?.toISOString() ?? null]);
    return { userId, plan, proUntil };
  };
  repo.findExistingUserIds = async (ids) => ids;
  subscriberImpl = async () => activeSubscriber();
});

test('sync: una suscripción activa pasa a PRO por la tienda', async () => {
  let askedFor;
  subscriberImpl = async (id) => {
    askedFor = id;
    return activeSubscriber();
  };

  const result = await syncUser(7, NOW);

  assert.equal(askedFor, '7');
  assert.equal(result.plan, 'PRO');
  assert.equal(result.proSource, 'store');
  assert.equal(result.proUntil.toISOString(), '2026-11-17T16:00:00.000Z');
  assert.equal(calls[0][0], 'upsert');
  assert.equal(calls[0][2].productId, 'monthly');
  assert.deepEqual(calls[1], ['plan', 7, 'PRO', '2026-11-17T16:00:00.000Z']);
});

test('sync: sin entitlement y sin regalo queda FREE', async () => {
  subscriberImpl = async () => ({ entitlements: {}, subscriptions: {} });
  repo.lockPlanInputs = async () => ({ plan: 'PRO', giftPro: false, giftProUntil: null, storeExpiresAt: new Date('2026-10-01T00:00:00Z') });

  const result = await syncUser(7, NOW);

  assert.deepEqual(result, { plan: 'FREE', proUntil: null, proSource: null });
  assert.equal(calls[0][2].expiresAt, null);
});

test('sync: conserva el regalo sin vencimiento aunque la tienda no tenga nada', async () => {
  subscriberImpl = async () => ({ entitlements: {}, subscriptions: {} });
  repo.lockPlanInputs = async () => ({ plan: 'PRO', giftPro: true, giftProUntil: null, storeExpiresAt: null });

  const result = await syncUser(7, NOW);

  assert.deepEqual(result, { plan: 'PRO', proUntil: null, proSource: 'gift' });
});

test('sync: sandbox con REVENUECAT_ALLOW_SANDBOX apagado no da PRO', async () => {
  settings.allowSandbox = false;
  subscriberImpl = async () => activeSubscriber('2026-11-17T15:00:00Z', true);

  const result = await syncUser(7, NOW);

  assert.equal(result.plan, 'FREE');
});

test('sync: si RevenueCat falla no toca la base', async () => {
  subscriberImpl = async () => {
    throw new AppError('x', 502, 'SUBSCRIPTION_PROVIDER_ERROR');
  };

  await assert.rejects(syncUser(7, NOW), { status: 502, code: 'SUBSCRIPTION_PROVIDER_ERROR' });
  assert.deepEqual(calls, []);
});

test('sync: usuario inexistente responde 404', async () => {
  repo.lockPlanInputs = async () => null;

  await assert.rejects(syncUser(99, NOW), { status: 404, code: 'USER_NOT_FOUND' });
});

test('regalo: guarda el regalo y recalcula con la tienda', async () => {
  repo.lockPlanInputs = async () => ({
    plan: 'PRO',
    giftPro: false,
    giftProUntil: null,
    storeExpiresAt: new Date('2026-11-17T15:00:00Z'),
  });

  const result = await saveGift(5, () => ({ giftPro: true, giftProUntil: new Date('2026-12-01T00:00:00Z') }), NOW);

  assert.deepEqual(calls[0], ['gift', 5, { giftPro: true, giftProUntil: new Date('2026-12-01T00:00:00Z') }]);
  assert.equal(result.userId, 5);
  assert.equal(result.proSource, 'both');
  assert.equal(result.proUntil.toISOString(), '2026-12-01T00:00:00.000Z');
});

test('regalo: quitar el regalo a quien paga lo deja PRO por la tienda', async () => {
  repo.lockPlanInputs = async () => ({
    plan: 'PRO',
    giftPro: true,
    giftProUntil: null,
    storeExpiresAt: new Date('2026-11-17T15:00:00Z'),
  });

  const result = await saveGift(5, () => ({ giftPro: false, giftProUntil: null }), NOW);

  assert.equal(result.plan, 'PRO');
  assert.equal(result.proSource, 'store');
  assert.equal(calls.some(([kind]) => kind === 'upsert'), false);
});

test('regalo: usuario inexistente devuelve null', async () => {
  repo.lockPlanInputs = async () => null;

  assert.equal(await saveGift(99, () => ({ giftPro: false, giftProUntil: null }), NOW), null);
});

test('webhook: ids del evento, sin anónimos ni repetidos', () => {
  assert.deepEqual(webhookUserIds({ app_user_id: '7' }), [7]);
  assert.deepEqual(webhookUserIds({ app_user_id: '$RCAnonymousID:abc' }), []);
  assert.deepEqual(
    webhookUserIds({ type: 'TRANSFER', app_user_id: '7', transferred_from: ['$RCAnonymousID:x', '7'], transferred_to: ['9'] }),
    [7, 9]
  );
  assert.deepEqual(webhookUserIds({ app_user_id: 'abc' }), []);
  assert.deepEqual(webhookUserIds(undefined), []);
});

test('webhook: TEST no sincroniza nada', async () => {
  repo.findExistingUserIds = async () => assert.fail('no debería buscar usuarios');

  assert.deepEqual(await handleWebhookEvent({ type: 'TEST', app_user_id: '7' }), { synced: [] });
});

test('webhook: sincroniza solo los usuarios que existen', async () => {
  repo.findExistingUserIds = async (ids) => ids.filter((id) => id !== 9);
  const synced = [];
  subscriberImpl = async (id) => {
    synced.push(id);
    return activeSubscriber();
  };

  const result = await handleWebhookEvent({ type: 'TRANSFER', transferred_from: ['7'], transferred_to: ['9'] });

  assert.deepEqual(result, { synced: [7] });
  assert.deepEqual(synced, ['7']);
});

test('webhook: si un sync falla, el error sale para que RevenueCat reintente', async () => {
  subscriberImpl = async () => {
    throw new AppError('x', 502, 'SUBSCRIPTION_PROVIDER_ERROR');
  };

  await assert.rejects(handleWebhookEvent({ type: 'RENEWAL', app_user_id: '7' }), { status: 502 });
});
```

- [ ] **Step 3: Correr y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/subscription.service.test.js`
Expected: FAIL (no existe `subscription.service.js`).

- [ ] **Step 4: Implementar el servicio**

`backend/src/modules/subscription/subscription.service.js`:

```js
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import { computeEffectivePlan } from './effectivePlan.js';
import { fetchSubscriber } from './revenuecat.client.js';
import { readStoreSubscription } from './subscriberState.js';
import {
  findExistingUserIds,
  inTransaction,
  lockPlanInputs,
  setEffectivePlan,
  setGift,
  upsertStoreSubscription,
} from './subscription.repository.js';

// Aplica la regla con los datos ya actualizados y guarda el plan efectivo.
const savePlan = async (client, userId, inputs, now) => {
  const effective = computeEffectivePlan(inputs, now);
  const saved = await setEffectivePlan(client, userId, effective);
  if (inputs.plan !== effective.plan) {
    console.info(`[subscription] usuario ${userId}: ${inputs.plan} -> ${effective.plan} (${effective.proSource ?? 'sin PRO'})`);
  }
  return { plan: saved.plan, proUntil: saved.proUntil, proSource: effective.proSource };
};

/**
 * Lee el estado real del usuario en RevenueCat y recalcula su plan. Se puede
 * llamar las veces que sea: el resultado depende solo de ese estado.
 */
export const syncUser = async (userId, now = new Date()) => {
  const subscriber = await fetchSubscriber(String(userId));
  const store = readStoreSubscription(subscriber, { allowSandbox: config.revenuecat.allowSandbox });

  return inTransaction(async (client) => {
    const inputs = await lockPlanInputs(client, userId);
    if (!inputs) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    await upsertStoreSubscription(client, userId, store);
    return savePlan(client, userId, { ...inputs, storeExpiresAt: store.expiresAt }, now);
  });
};

/**
 * Cambia el PRO regalado y recalcula el plan. giftFor recibe el estado actual
 * ({ plan, giftPro, giftProUntil, storeExpiresAt }) y devuelve el regalo nuevo.
 * @returns {Promise<Object|null>} null si el usuario no existe.
 */
export const saveGift = (userId, giftFor, now = new Date()) =>
  inTransaction(async (client) => {
    const inputs = await lockPlanInputs(client, userId);
    if (!inputs) return null;
    const gift = giftFor(inputs);
    await setGift(client, userId, gift);
    return { userId, ...(await savePlan(client, userId, { ...inputs, ...gift }, now)) };
  });

const USER_ID_PATTERN = /^\d+$/;

/** Usuarios de NutriLife que menciona un evento de RevenueCat. */
export const webhookUserIds = (event) => {
  const ids = [event?.app_user_id, ...(event?.transferred_from ?? []), ...(event?.transferred_to ?? [])];
  const valid = ids.filter((id) => typeof id === 'string' && USER_ID_PATTERN.test(id)).map(Number);
  return [...new Set(valid)];
};

/** El contenido del evento solo dice a quién sincronizar, nunca qué plan poner. */
export const handleWebhookEvent = async (event) => {
  if (event?.type === 'TEST') return { synced: [] };
  const candidates = webhookUserIds(event);
  if (candidates.length === 0) return { synced: [] };

  const existing = await findExistingUserIds(candidates);
  for (const userId of existing) {
    await syncUser(userId);
  }
  return { synced: existing };
};
```

- [ ] **Step 5: Correr y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/subscription.service.test.js`
Expected: PASS (13 pruebas).

- [ ] **Step 6: Commit**

```bash
git add backend/src/modules/subscription/subscription.repository.js backend/src/modules/subscription/subscription.service.js backend/test/subscription/subscription.service.test.js
git commit -m "feat(suscripcion): sync con RevenueCat y regalo recalculado"
```

---

### Task 4: Rutas del webhook y del sync

**Files:**
- Create: `backend/src/modules/subscription/webhookAuth.middleware.js`
- Create: `backend/src/modules/subscription/subscription.controller.js`
- Create: `backend/src/modules/subscription/subscription.routes.js`
- Modify: `backend/src/middleware/rateLimit.middleware.js`
- Modify: `backend/src/middleware/activityLogger.middleware.js:5`
- Modify: `backend/src/app.js`
- Test: `backend/test/subscription/webhookAuth.middleware.test.js`, `backend/test/subscription/subscription.controller.test.js`

**Interfaces:**
- Consumes: `syncUser`, `handleWebhookEvent` (Task 3); `config.revenuecat.webhookAuth`, `config.rateLimit.subscriptionSyncPerMinute` (Task 2).
- Produces: `POST /api/v1/subscription/webhook` (sin JWT, header `Authorization`), `POST /api/v1/subscription/sync` (JWT) → `{ success, message, data: { plan, proUntil, proSource } }`.

- [ ] **Step 1: Escribir las pruebas del middleware y del controller**

`backend/test/subscription/webhookAuth.middleware.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const settings = { webhookAuth: 'secreto-largo' };
mock.module(src('config/env_config.js'), { exports: { config: { revenuecat: settings } } });

const { verifyWebhookAuth } = await import(src('modules/subscription/webhookAuth.middleware.js'));

const run = (header) => {
  let received = 'sin llamar';
  const req = { get: (name) => (name.toLowerCase() === 'authorization' ? header : undefined) };
  verifyWebhookAuth(req, {}, (error) => {
    received = error;
  });
  return received;
};

test('el valor correcto pasa', () => {
  settings.webhookAuth = 'secreto-largo';
  assert.equal(run('secreto-largo'), undefined);
});

test('un valor incorrecto responde 401', () => {
  settings.webhookAuth = 'secreto-largo';
  assert.equal(run('otro').status, 401);
  assert.equal(run(undefined).status, 401);
});

test('sin REVENUECAT_WEBHOOK_AUTH configurado rechaza todo', () => {
  settings.webhookAuth = undefined;
  assert.equal(run('').status, 401);
  assert.equal(run('cualquiera').status, 401);
});
```

`backend/test/subscription/subscription.controller.test.js`:

```js
import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
let syncImpl;
let webhookImpl;
mock.module(src('modules/subscription/subscription.service.js'), {
  namedExports: {
    syncUser: (...args) => syncImpl(...args),
    handleWebhookEvent: (...args) => webhookImpl(...args),
  },
});

const { receiveWebhook, syncSubscription } = await import(src('modules/subscription/subscription.controller.js'));

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

test('sync: sincroniza al usuario autenticado', async () => {
  let askedFor;
  syncImpl = async (userId) => {
    askedFor = userId;
    return { plan: 'PRO', proUntil: null, proSource: 'store' };
  };
  const res = fakeRes();

  await syncSubscription({ user: { userId: 7 } }, res, () => assert.fail());

  assert.equal(askedFor, 7);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, { plan: 'PRO', proUntil: null, proSource: 'store' });
});

test('sync: un error pasa al errorHandler', async () => {
  const failure = new Error('falla');
  syncImpl = async () => {
    throw failure;
  };
  let received;

  await syncSubscription({ user: { userId: 7 } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, failure);
});

test('webhook: procesa el evento del body', async () => {
  let event;
  webhookImpl = async (e) => {
    event = e;
    return { synced: [7] };
  };
  const res = fakeRes();

  await receiveWebhook({ body: { event: { type: 'RENEWAL', app_user_id: '7' } } }, res, () => assert.fail());

  assert.deepEqual(event, { type: 'RENEWAL', app_user_id: '7' });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, { synced: [7] });
});
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/webhookAuth.middleware.test.js test/subscription/subscription.controller.test.js`
Expected: FAIL (no existen los módulos).

- [ ] **Step 3: Implementar middleware, controller y rutas**

`backend/src/modules/subscription/webhookAuth.middleware.js`:

```js
import { timingSafeEqual } from 'node:crypto';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const sameSecret = (received, expected) => {
  const a = Buffer.from(received ?? '');
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
};

/** RevenueCat manda en Authorization el valor configurado en su dashboard. */
export const verifyWebhookAuth = (req, res, next) => {
  const expected = config.revenuecat.webhookAuth;
  if (!expected || !sameSecret(req.get('authorization'), expected)) {
    return next(new AppError('Invalid token', 401, 'UNAUTHORIZED', ['Invalid token']));
  }
  return next();
};
```

`backend/src/modules/subscription/subscription.controller.js`:

```js
import { successResponse } from '../../utils/response.js';
import { handleWebhookEvent, syncUser } from './subscription.service.js';

const handle = (run, message) => async (req, res, next) => {
  try {
    return successResponse(res, await run(req), message);
  } catch (error) {
    next(error);
  }
};

export const syncSubscription = handle((req) => syncUser(req.user.userId), 'Suscripción sincronizada');
export const receiveWebhook = handle((req) => handleWebhookEvent(req.body?.event), 'Evento procesado');
```

`backend/src/modules/subscription/subscription.routes.js`:

```js
import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { subscriptionSyncRateLimit } from '../../middleware/rateLimit.middleware.js';
import { receiveWebhook, syncSubscription } from './subscription.controller.js';
import { verifyWebhookAuth } from './webhookAuth.middleware.js';

const router = Router();

/**
 * @swagger
 * /api/v1/subscription/webhook:
 *   post:
 *     tags: [Subscription]
 *     summary: Webhook de RevenueCat
 *     description: >
 *       Sin JWT. El header Authorization debe ser igual a REVENUECAT_WEBHOOK_AUTH.
 *       Sincroniza a los usuarios del evento leyendo su estado real en RevenueCat.
 *     responses:
 *       200:
 *         description: Procesado ({ synced })
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       502:
 *         description: RevenueCat no respondió (SUBSCRIPTION_PROVIDER_ERROR). RevenueCat reintenta.
 */
router.post('/webhook', verifyWebhookAuth, receiveWebhook);

/**
 * @swagger
 * /api/v1/subscription/sync:
 *   post:
 *     tags: [Subscription]
 *     summary: Sincroniza la suscripción del usuario autenticado
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Plan efectivo ({ plan, proUntil, proSource })
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       429:
 *         description: Límite por minuto (RATE_LIMIT_EXCEEDED)
 *       502:
 *         description: RevenueCat no respondió (SUBSCRIPTION_PROVIDER_ERROR)
 */
router.post('/sync', authenticateToken(['USER', 'ADMIN']), subscriptionSyncRateLimit, syncSubscription);

export default router;
```

En `backend/src/middleware/rateLimit.middleware.js`, al final:

```js
/**
 * Rate limit del sync de suscripción (la app lo llama al comprar o restaurar).
 * Default: 10 req/min por usuario.
 */
export const subscriptionSyncRateLimit = buildMiddleware({
  points: config.rateLimit.subscriptionSyncPerMinute,
  keyPrefix: 'rl:subscription-sync',
  keyExtractor: (req) => `subscription:user:${req.user?.userId ?? req.ip}`,
});
```

En `backend/src/middleware/activityLogger.middleware.js` cambiar la línea 5 y su comentario:

```js
// Rutas que no aportan valor de auditoría (ruido / health checks / docs),
// que se registran de forma explícita con mayor semántica (/auth) o que llama
// un servicio externo (el webhook de RevenueCat, que parecería un bot).
const IGNORED_PREFIXES = ['/api/v1/health', '/api-docs', '/favicon', '/api/v1/auth', '/api/v1/subscription/webhook'];
```

En `backend/src/app.js`: agregar el import junto a los otros módulos

```js
import subscriptionRoutes from './modules/subscription/subscription.routes.js';
```

y la ruta después de `hydrationRoutes`:

```js
app.use('/api/v1/subscription', subscriptionRoutes);
```

- [ ] **Step 4: Correr y ver que pasan**

Run: `cd backend && node --experimental-test-module-mocks --test test/subscription/webhookAuth.middleware.test.js test/subscription/subscription.controller.test.js`
Expected: PASS (6 pruebas).

- [ ] **Step 5: Suite completa y arranque**

Run: `cd backend && npm test`
Expected: PASS.

Run: `cd backend && node -e "import('./src/app.js').then(() => { console.log('ok'); process.exit(0); })"`
Expected: imprime `ok` (los imports y el montaje no fallan).

- [ ] **Step 6: Commit**

```bash
git add backend/src/modules/subscription/webhookAuth.middleware.js backend/src/modules/subscription/subscription.controller.js backend/src/modules/subscription/subscription.routes.js backend/src/middleware/rateLimit.middleware.js backend/src/middleware/activityLogger.middleware.js backend/src/app.js backend/test/subscription/webhookAuth.middleware.test.js backend/test/subscription/subscription.controller.test.js
git commit -m "feat(suscripcion): webhook de RevenueCat y sync de la app"
```

---

### Task 5: El panel regala sobre el regalo; detalle y perfil con `proSource`

**Files:**
- Modify: `backend/src/modules/admin/admin.service.js`
- Modify: `backend/src/modules/admin/admin.repository.js` (borrar `findUserPlanState` y `updateUserPlan`; `findUserDetail` con regalo y suscripción)
- Modify: `backend/src/modules/user/user.repository.js`, `backend/src/modules/user/user.service.js`
- Test: `backend/test/admin/admin.service.test.js`, `backend/test/user/user.service.test.js`

**Interfaces:**
- Consumes: `saveGift` (Task 3), `computeEffectivePlan` (Task 1), `computeProUntil(current, duration, now)` de `proGift.js` (sin cambios).
- Produces: `PATCH /admin/users/:id/plan` → `{ userId, plan, proUntil, proSource }`. Detalle admin: `profile` agrega `giftPro`, `giftProUntil`, `proSource`, `subscription: { productId, store, expiresAt, willRenew, billingIssue, environment } | null`. Perfil (`GET /user/profile`) agrega `proSource`.

- [ ] **Step 1: Reescribir las pruebas del cambio de plan y agregar la del detalle**

En `backend/test/admin/admin.service.test.js`:

1. Quitar `'findUserPlanState'` y `'updateUserPlan'` de `REPO_EXPORTS`.
2. Después del `mock.module` de `events.service.js`, agregar:

```js
let saveGiftImpl;
mock.module(src('modules/subscription/subscription.service.js'), {
  exports: { saveGift: (...args) => saveGiftImpl(...args) },
});
```

3. Reemplazar desde `const capturePlanUpdate = () => {` hasta el final de la prueba del 404 del plan (la que usa `updateUserPlanService(99, 'PRO', '7d', NOW)`) por:

```js
// Corre giftFor con el regalo indicado y devuelve el regalo nuevo.
const giftAfter = async (current, plan, duration) => {
  let gift;
  saveGiftImpl = async (userId, giftFor, now) => {
    gift = giftFor({ plan: 'FREE', storeExpiresAt: null, ...current });
    return { userId, plan: 'PRO', proUntil: null, proSource: 'gift', now };
  };
  await updateUserPlanService(5, plan, duration, NOW);
  return { ...gift, giftProUntil: gift.giftProUntil?.toISOString() ?? null };
};

test('plan: regalar 7 días a quien no tiene regalo', async () => {
  assert.deepEqual(await giftAfter({ giftPro: false, giftProUntil: null }, 'PRO', '7d'), {
    giftPro: true,
    giftProUntil: '2026-10-24T15:00:00.000Z',
  });
});

test('plan: extender un regalo con fecha suma a esa fecha', async () => {
  const gift = await giftAfter({ giftPro: true, giftProUntil: new Date('2026-11-01T00:00:00Z') }, 'PRO', '1m');
  assert.equal(gift.giftProUntil, '2026-12-01T00:00:00.000Z');
});

test('plan: el regalo cuenta desde ahora aunque pague en la tienda', async () => {
  const gift = await giftAfter(
    { plan: 'PRO', giftPro: false, giftProUntil: null, storeExpiresAt: new Date('2026-12-01T00:00:00Z') },
    'PRO',
    '7d'
  );
  assert.equal(gift.giftProUntil, '2026-10-24T15:00:00.000Z');
});

test('plan: regalo sin vencimiento', async () => {
  assert.deepEqual(await giftAfter({ giftPro: false, giftProUntil: null }, 'PRO', 'forever'), {
    giftPro: true,
    giftProUntil: null,
  });
});

test('plan: FREE quita el regalo', async () => {
  assert.deepEqual(await giftAfter({ giftPro: true, giftProUntil: new Date('2026-11-01T00:00:00Z') }, 'FREE'), {
    giftPro: false,
    giftProUntil: null,
  });
});

test('plan: devuelve lo que calculó saveGift y le pasa la hora', async () => {
  saveGiftImpl = async (userId, giftFor, now) => ({ userId, plan: 'PRO', proUntil: null, proSource: 'both', now });

  const result = await updateUserPlanService(5, 'FREE', undefined, NOW);

  assert.equal(result.proSource, 'both');
  assert.equal(result.now, NOW);
});

test('plan: usuario inexistente responde 404', async () => {
  saveGiftImpl = async () => null;

  await assert.rejects(updateUserPlanService(99, 'PRO', '7d', NOW), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});
```

4. Al final del archivo agregar:

```js
test('detalle: agrega de dónde viene el PRO', async () => {
  repo.findUserDetail = async () => ({
    profile: {
      userId: 5,
      giftPro: false,
      giftProUntil: null,
      subscription: { expiresAt: '2026-11-17T15:00:00Z', productId: 'monthly' },
    },
    usage: {},
    series: [],
    byModule: [],
    recentEvents: [],
    waterRows: [],
  });

  const detail = await getUserDetailService(5, NIGHT_IN_BOGOTA);

  assert.equal(detail.profile.proSource, 'store');
  assert.equal(detail.profile.subscription.productId, 'monthly');
});

test('detalle: sin suscripción ni regalo no hay proSource', async () => {
  repo.findUserDetail = async () => ({
    profile: { userId: 5, giftPro: false, giftProUntil: null, subscription: null },
    usage: {},
    series: [],
    byModule: [],
    recentEvents: [],
    waterRows: [],
  });

  const detail = await getUserDetailService(5, NIGHT_IN_BOGOTA);

  assert.equal(detail.profile.proSource, null);
});
```

En `backend/test/user/user.service.test.js`: agregar `getUserProfile` al import del servicio:

```js
const { deleteUserAccount, getUserProfile, setUserPassword } = await import(src('modules/user/user.service.js'));
```

y al final:

```js
test('perfil: agrega proSource y no expone los datos internos del plan', async () => {
  repo.findUserProfileById = async () => ({
    userId: 7,
    plan: 'PRO',
    proUntil: null,
    giftPro: true,
    giftProUntil: null,
    storeExpiresAt: null,
  });

  const profile = await getUserProfile(7);

  assert.equal(profile.proSource, 'gift');
  assert.equal('giftPro' in profile, false);
  assert.equal('giftProUntil' in profile, false);
  assert.equal('storeExpiresAt' in profile, false);
});
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `cd backend && node --experimental-test-module-mocks --test test/admin/admin.service.test.js test/user/user.service.test.js`
Expected: FAIL (el servicio aún llama a `findUserPlanState`; no hay `proSource`).

- [ ] **Step 3: Implementar el admin**

En `backend/src/modules/admin/admin.service.js`:

- Quitar `findUserPlanState` y `updateUserPlan` del import de `./admin.repository.js`.
- Agregar imports:

```js
import { computeEffectivePlan } from '../subscription/effectivePlan.js';
import { saveGift } from '../subscription/subscription.service.js';
```

- Reemplazar `getUserDetailService` y `updateUserPlanService` por:

```js
/** Detalle de un usuario. */
export const getUserDetailService = (userId, now = new Date()) =>
  wrap(async () => {
    const detail = await findUserDetail(userId);
    if (!detail) throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    const { waterRows, profile, ...rest } = detail;
    const { proSource } = computeEffectivePlan(
      { giftPro: profile.giftPro, giftProUntil: profile.giftProUntil, storeExpiresAt: profile.subscription?.expiresAt },
      now
    );
    return {
      ...rest,
      profile: { ...profile, proSource },
      water: summarizeWater(toHistory(waterRows), dayInTimeZone(now, PANEL_TIMEZONE)),
    };
  });

// El regalo en la forma que espera computeProUntil.
const giftPlanState = ({ giftPro, giftProUntil }) => ({ plan: giftPro ? 'PRO' : 'FREE', proUntil: giftProUntil });

/**
 * Cambia el PRO regalado de un usuario. PRO lleva la duración (ver proGift.js);
 * FREE quita el regalo. Lo pagado en la tienda no se toca: el plan se recalcula.
 */
export const updateUserPlanService = (userId, plan, duration, now = new Date()) =>
  wrap(async () => {
    const updated = await saveGift(
      userId,
      (current) =>
        plan === 'PRO'
          ? { giftPro: true, giftProUntil: computeProUntil(giftPlanState(current), duration, now) }
          : { giftPro: false, giftProUntil: null },
      now
    );
    if (!updated) throw userNotFound();
    return updated;
  });
```

En `backend/src/modules/admin/admin.repository.js`:

- Borrar `findUserPlanState` y `updateUserPlan` (con sus comentarios JSDoc).
- En `findUserDetail`, en `profileQuery`, agregar después de `u.pro_until AS "proUntil",`:

```sql
      u.gift_pro AS "giftPro",
      u.gift_pro_until AS "giftProUntil",
      CASE WHEN ss.user_id IS NULL THEN NULL ELSE json_build_object(
        'productId', ss.product_id,
        'store', ss.store,
        'expiresAt', ss.expires_at,
        'willRenew', ss.will_renew,
        'billingIssue', ss.billing_issue,
        'environment', ss.environment
      ) END AS subscription,
```

y después de `INNER JOIN plans p ON p.plan_id = u.plan_id` (el de `profileQuery`):

```sql
    LEFT JOIN store_subscriptions ss ON ss.user_id = u.user_id
```

- Revisar con `grep -rn "findUserPlanState\|updateUserPlan(" backend/src` que no quede ningún uso (el controller `updateUserPlan` es otra función y se queda).

- [ ] **Step 4: Implementar el perfil**

En `backend/src/modules/user/user.repository.js`, en `profileSelectQuery` agregar después de `u.pro_until AS "proUntil",`:

```sql
    u.gift_pro AS "giftPro",
    u.gift_pro_until AS "giftProUntil",
    ss.expires_at AS "storeExpiresAt",
```

y después de `INNER JOIN plans p ON p.plan_id = u.plan_id`:

```sql
  LEFT JOIN store_subscriptions ss ON ss.user_id = u.user_id
```

En `backend/src/modules/user/user.service.js`:

```js
import { computeEffectivePlan } from '../subscription/effectivePlan.js';

// El perfil dice de dónde viene el PRO, sin exponer las columnas internas.
const withProSource = ({ giftPro, giftProUntil, storeExpiresAt, ...profile }) => ({
  ...profile,
  proSource: computeEffectivePlan({ giftPro, giftProUntil, storeExpiresAt }).proSource,
});
```

y en `getUserProfile` cambiar `return user;` por `return withProSource(user);`. (`getPhysicalHistory` también usa `findUserProfileById`, pero solo para ver que existe: no cambia.)

En `backend/src/config/swagger.schemas.js`, en el schema `User`, después del bloque `plan:` (las tres líneas con `type: string` y `example: FREE`):

```js
 *         proUntil:
 *           type: string
 *           format: date-time
 *           nullable: true
 *           description: Fin del PRO. Null con PRO = sin vencimiento.
 *         proSource:
 *           type: string
 *           nullable: true
 *           enum: [gift, store, both]
 *           description: De dónde viene el PRO (regalo del panel, tienda o ambos).
```

- [ ] **Step 5: Correr y ver que pasan**

Run: `cd backend && npm test`
Expected: PASS.

- [ ] **Step 6: Commit y push del backend**

```bash
git pull
git add backend/src/modules/admin/admin.service.js backend/src/modules/admin/admin.repository.js backend/src/modules/user/user.repository.js backend/src/modules/user/user.service.js backend/src/config/swagger.schemas.js backend/test/admin/admin.service.test.js backend/test/user/user.service.test.js
git commit -m "feat(suscripcion): el panel regala sin tocar lo pagado; proSource en perfil y detalle"
```

**Antes de pushear:** la migración tiene que estar aplicada en producción, porque el código nuevo lee `gift_pro` y `store_subscriptions`. Pedirle al usuario que la aplique (Task 11, paso 1) y pushear cuando confirme:

```bash
git push origin main
```

---

### Task 6: Panel admin muestra el origen del PRO y regala sobre el regalo

**Files:**
- Modify: `admin-panel/src/types/admin.ts`
- Modify: `admin-panel/src/pages/UserDetail.tsx`

**Interfaces:**
- Consumes: detalle admin con `giftPro`, `giftProUntil`, `proSource`, `subscription` (Task 5).

- [ ] **Step 1: Tipos**

En `admin-panel/src/types/admin.ts`, antes de `export interface UserDetail`:

```ts
export type ProSource = 'gift' | 'store' | 'both';

export interface StoreSubscription {
  productId: string | null;
  store: string | null;
  expiresAt: string | null;
  willRenew: boolean;
  billingIssue: boolean;
  environment: 'sandbox' | 'production' | null;
}
```

y dentro de `UserDetail.profile`, después de `proUntil: string | null;`:

```ts
    giftPro: boolean;
    giftProUntil: string | null;
    proSource: ProSource | null;
    subscription: StoreSubscription | null;
```

- [ ] **Step 2: Cabecera del detalle**

En `admin-panel/src/pages/UserDetail.tsx`, debajo de la línea `{profile.proUntil ? \`PRO hasta el ...\` : 'PRO sin vencimiento'}` (dentro del mismo bloque `{isPro && (...)}`), agregar después del `</p>`:

```tsx
              {isPro && profile.proSource && (
                <p className="text-sm text-white/80">{proSourceLabel(profile)}</p>
              )}
```

y al final del archivo (fuera de los componentes):

```tsx
const STORE_LABELS: Record<string, string> = {
  play_store: 'Google Play',
  app_store: 'App Store',
  test_store: 'Test Store',
};

function proSourceLabel(profile: UserDetail['profile']): string {
  const sub = profile.subscription;
  const store = sub ? `${sub.productId ?? 'suscripción'} en ${STORE_LABELS[sub.store ?? ''] ?? sub.store ?? 'la tienda'}` : '';
  const renew = sub ? (sub.billingIssue ? ' · problema de cobro' : sub.willRenew ? ' · se renueva' : ' · no se renueva') : '';
  const sandbox = sub?.environment === 'sandbox' ? ' · prueba' : '';
  if (profile.proSource === 'gift') return 'Regalado desde el panel';
  if (profile.proSource === 'store') return `Pagado: ${store}${renew}${sandbox}`;
  return `Regalado y pagado: ${store}${renew}${sandbox}`;
}
```

(Importar `UserDetail` como tipo si el archivo no lo importa ya: `import type { ..., UserDetail } from '../types/admin';`.)

- [ ] **Step 3: Los botones y el diálogo trabajan sobre el regalo**

En `UserDetail.tsx`, justo después de donde se define `isPro` (en el componente de la página), agregar:

```tsx
  // El panel solo maneja el regalo; lo pagado en la tienda no se toca desde aquí.
  const giftActive =
    profile.giftPro && (!profile.giftProUntil || new Date(profile.giftProUntil) > new Date());
  const giftState = { plan: (giftActive ? 'PRO' : 'FREE') as Plan, proUntil: giftActive ? profile.giftProUntil : null };
```

Cambiar las condiciones de los botones:
- `{(!isPro || profile.proUntil) && (` → `{(!giftActive || profile.giftProUntil) && (`
- El texto `{isPro ? 'Extender PRO' : 'Regalar PRO'}` → `{giftActive ? 'Extender regalo' : 'Regalar PRO'}`
- El botón de quitar: `{isPro && (` → `{giftActive && (`, y su texto pasa a `Quitar regalo`.

En el `<PlanDialog ... />`:
- `current={{ plan: profile.plan, proUntil: profile.proUntil }}` → `current={giftState}`
- `onChanged={({ plan, proUntil }) => setData(...)}` → `onChanged={() => load()}`. Recarga el detalle completo con el `load` que ya existe en la página (`useCallback` que llama a `fetchUserDetail`), porque ahora cambian varias cosas a la vez (plan, regalo, origen).

En `PlanDialog`, el texto de quitar `${name} volverá al plan FREE.` → `${name} pierde el PRO regalado. Si paga en la tienda, sigue PRO.` y el título `'Quitar el plan PRO'` → `'Quitar el PRO regalado'`. Cambiar la firma de `onChanged` a `onChanged: () => void` y llamarla como `onChanged();` después de `updateUserPlan`.

- [ ] **Step 4: Compilar**

Run: `cd admin-panel && npm run build`
Expected: compila sin errores de TypeScript.

- [ ] **Step 5: Commit (sin push hasta que el usuario diga)**

```bash
git add admin-panel/src/types/admin.ts admin-panel/src/pages/UserDetail.tsx
git commit -m "feat(admin-panel): origen del PRO y regalo separado de la suscripción"
```

---

### Task 7: `PurchaseService` y sesión en RevenueCat

**Files:**
- Modify: `nutrilife/pubspec.yaml` (vía `flutter pub add`)
- Create: `nutrilife/lib/core/services/purchase_service.dart`
- Modify: `nutrilife/lib/main.dart`
- Modify: `nutrilife/lib/core/services/session_service.dart`
- Create: `nutrilife/test/helpers/fake_purchase_service.dart`
- Test: `nutrilife/test/core/services/purchase_offer_test.dart`

**Interfaces:**
- Produces:
  - `const kProEntitlement = 'nutrilife_pro'`
  - `enum PremiumPlan { monthly, yearly }`
  - `class PlanPrice { String priceString; double price; }`
  - `class PremiumOffer { PlanPrice? monthly; PlanPrice? yearly; bool get isEmpty; PlanPrice? priceOf(PremiumPlan); int? get yearlySavingsPercent; }`
  - `enum PurchaseOutcome { success, cancelled, pending, alreadyOwned, notAllowed, storeUnavailable, failed }`
  - `enum RestoreOutcome { restored, nothingFound, failed }`
  - `class PurchaseLoadException implements Exception`
  - `abstract class PurchaseService { static PurchaseService instance; bool get isEnabled; Future<void> init(); Future<void> logIn(String userId); Future<void> logOut(); Future<PremiumOffer> loadOffer(); Future<PurchaseOutcome> purchase(PremiumPlan plan); Future<RestoreOutcome> restore(); Future<String?> managementUrl(); }`
  - `class FakePurchaseService implements PurchaseService` (en `test/helpers`).

- [ ] **Step 1: Agregar la dependencia**

Run: `cd nutrilife && flutter pub add purchases_flutter`
Expected: `pubspec.yaml` con `purchases_flutter: ^<versión actual>`. Debe ser una versión con Test Store y con `Purchases.purchase(PurchaseParams)` (9.x o más nueva). Si la versión resuelta no tiene `Purchases.purchase`, usar en el Step 4 `Purchases.purchasePackage(package)`, que devuelve `CustomerInfo` directo.

- [ ] **Step 2: Escribir la prueba de `PremiumOffer`**

`nutrilife/test/core/services/purchase_offer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';

void main() {
  const monthly = PlanPrice(priceString: '\$4.99', price: 4.99);
  const yearly = PlanPrice(priceString: '\$29.99', price: 29.99);

  test('el anual ahorra 50% frente a doce meses', () {
    expect(const PremiumOffer(monthly: monthly, yearly: yearly).yearlySavingsPercent, 50);
  });

  test('sin uno de los dos precios no hay ahorro', () {
    expect(const PremiumOffer(yearly: yearly).yearlySavingsPercent, isNull);
  });

  test('un ahorro menor a 5% no se muestra', () {
    const almostSame = PlanPrice(priceString: '\$58', price: 58);
    expect(const PremiumOffer(monthly: monthly, yearly: almostSame).yearlySavingsPercent, isNull);
  });

  test('priceOf e isEmpty', () {
    const offer = PremiumOffer(monthly: monthly);
    expect(offer.priceOf(PremiumPlan.monthly), monthly);
    expect(offer.priceOf(PremiumPlan.yearly), isNull);
    expect(offer.isEmpty, isFalse);
    expect(const PremiumOffer().isEmpty, isTrue);
  });

  test('sin key las compras quedan apagadas', () {
    expect(RevenueCatPurchaseService('').isEnabled, isFalse);
    expect(RevenueCatPurchaseService('test_abc').isEnabled, isTrue);
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `cd nutrilife && flutter test test/core/services/purchase_offer_test.dart`
Expected: FAIL (no existe `purchase_service.dart`).

- [ ] **Step 4: Implementar el servicio**

`nutrilife/lib/core/services/purchase_service.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Único archivo que conoce RevenueCat. El resto de la app usa PurchaseService,
// así las pruebas pueden cambiarlo por uno falso.

const kProEntitlement = 'nutrilife_pro';

enum PremiumPlan { monthly, yearly }

class PlanPrice {
  const PlanPrice({required this.priceString, required this.price});

  /// Precio con la moneda del país, listo para mostrar.
  final String priceString;
  final double price;
}

class PremiumOffer {
  const PremiumOffer({this.monthly, this.yearly});

  final PlanPrice? monthly;
  final PlanPrice? yearly;

  bool get isEmpty => monthly == null && yearly == null;

  PlanPrice? priceOf(PremiumPlan plan) => plan == PremiumPlan.monthly ? monthly : yearly;

  /// Cuánto ahorra el anual frente a doce meses del mensual, en %. Null si
  /// falta un precio o el ahorro es menor a 5%.
  int? get yearlySavingsPercent {
    final m = monthly?.price;
    final y = yearly?.price;
    if (m == null || y == null || m <= 0) return null;
    final percent = ((1 - y / (m * 12)) * 100).round();
    return percent >= 5 ? percent : null;
  }
}

enum PurchaseOutcome { success, cancelled, pending, alreadyOwned, notAllowed, storeUnavailable, failed }

enum RestoreOutcome { restored, nothingFound, failed }

/// No se pudieron cargar los precios (sin internet, sin offering, sin key).
class PurchaseLoadException implements Exception {
  const PurchaseLoadException();
}

abstract class PurchaseService {
  static PurchaseService instance = RevenueCatPurchaseService.fromEnvironment();

  /// false si la build no trae key: la pantalla premium dice "pagos pronto".
  bool get isEnabled;
  Future<void> init();
  Future<void> logIn(String userId);
  Future<void> logOut();
  Future<PremiumOffer> loadOffer();
  Future<PurchaseOutcome> purchase(PremiumPlan plan);
  Future<RestoreOutcome> restore();

  /// Página de la tienda para administrar o cancelar la suscripción.
  Future<String?> managementUrl();
}

class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this._apiKey);

  /// Las keys llegan por --dart-define. Hoy las dos son la de la Test Store.
  factory RevenueCatPurchaseService.fromEnvironment() {
    const androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
    const iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
    if (kIsWeb) return RevenueCatPurchaseService('');
    if (Platform.isAndroid) return RevenueCatPurchaseService(androidKey);
    if (Platform.isIOS) return RevenueCatPurchaseService(iosKey);
    return RevenueCatPurchaseService('');
  }

  final String _apiKey;
  bool _configured = false;
  Package? _monthly;
  Package? _yearly;

  @override
  bool get isEnabled => _apiKey.isNotEmpty;

  bool get _ready => isEnabled && _configured;

  @override
  Future<void> init() async {
    if (!isEnabled || _configured) return;
    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
    } catch (error) {
      debugPrint('[purchases] no se pudo configurar RevenueCat: $error');
    }
  }

  @override
  Future<void> logIn(String userId) async {
    if (!_ready) return;
    try {
      await Purchases.logIn(userId);
    } catch (error) {
      debugPrint('[purchases] logIn falló: $error');
    }
  }

  @override
  Future<void> logOut() async {
    if (!_ready) return;
    try {
      // Cerrar la sesión de un usuario anónimo lanza error.
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } catch (error) {
      debugPrint('[purchases] logOut falló: $error');
    }
  }

  @override
  Future<PremiumOffer> loadOffer() async {
    if (!_ready) throw const PurchaseLoadException();
    try {
      final current = (await Purchases.getOfferings()).current;
      _monthly = current?.monthly;
      _yearly = current?.annual;
    } catch (error) {
      debugPrint('[purchases] no se pudo cargar el offering: $error');
      throw const PurchaseLoadException();
    }
    final offer = PremiumOffer(monthly: _priceOf(_monthly), yearly: _priceOf(_yearly));
    if (offer.isEmpty) throw const PurchaseLoadException();
    return offer;
  }

  static PlanPrice? _priceOf(Package? package) => package == null
      ? null
      : PlanPrice(priceString: package.storeProduct.priceString, price: package.storeProduct.price);

  @override
  Future<PurchaseOutcome> purchase(PremiumPlan plan) async {
    if (!_ready) return PurchaseOutcome.storeUnavailable;
    if (_monthly == null && _yearly == null) {
      try {
        await loadOffer();
      } on PurchaseLoadException {
        return PurchaseOutcome.storeUnavailable;
      }
    }
    final package = plan == PremiumPlan.monthly ? _monthly : _yearly;
    if (package == null) return PurchaseOutcome.storeUnavailable;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active.containsKey(kProEntitlement)
          ? PurchaseOutcome.success
          : PurchaseOutcome.failed;
    } on PlatformException catch (error) {
      return _outcomeFor(PurchasesErrorHelper.getErrorCode(error));
    }
  }

  static PurchaseOutcome _outcomeFor(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        PurchasesErrorCode.productAlreadyPurchasedError => PurchaseOutcome.alreadyOwned,
        PurchasesErrorCode.purchaseNotAllowedError => PurchaseOutcome.notAllowed,
        PurchasesErrorCode.storeProblemError ||
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError =>
          PurchaseOutcome.storeUnavailable,
        _ => PurchaseOutcome.failed,
      };

  @override
  Future<RestoreOutcome> restore() async {
    if (!_ready) return RestoreOutcome.failed;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(kProEntitlement)
          ? RestoreOutcome.restored
          : RestoreOutcome.nothingFound;
    } catch (error) {
      debugPrint('[purchases] restaurar falló: $error');
      return RestoreOutcome.failed;
    }
  }

  @override
  Future<String?> managementUrl() async {
    if (!_ready) return null;
    try {
      return (await Purchases.getCustomerInfo()).managementURL;
    } catch (error) {
      debugPrint('[purchases] no se pudo leer la managementURL: $error');
      return null;
    }
  }
}
```

(Si `PurchasesErrorCode.offlineConnectionError` no existe en la versión resuelta, quitar solo esa línea.)

- [ ] **Step 5: Correr y ver que pasa**

Run: `cd nutrilife && flutter test test/core/services/purchase_offer_test.dart`
Expected: PASS (5 pruebas).

- [ ] **Step 6: Servicio falso para las pruebas**

`nutrilife/test/helpers/fake_purchase_service.dart`:

```dart
import 'package:nutrilife/core/services/purchase_service.dart';

/// PurchaseService configurable para las pruebas de widgets.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    this.isEnabled = true,
    this.offer = const PremiumOffer(
      monthly: PlanPrice(priceString: '\$4.99', price: 4.99),
      yearly: PlanPrice(priceString: '\$29.99', price: 29.99),
    ),
    this.loadFails = false,
    this.purchaseOutcome = PurchaseOutcome.success,
    this.restoreOutcome = RestoreOutcome.restored,
    this.url,
  });

  @override
  final bool isEnabled;
  PremiumOffer offer;
  bool loadFails;
  PurchaseOutcome purchaseOutcome;
  RestoreOutcome restoreOutcome;
  String? url;

  final List<PremiumPlan> purchased = [];
  int loadCalls = 0;
  int restoreCalls = 0;
  int managementUrlCalls = 0;
  final List<String> loggedIn = [];
  int logOutCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> logIn(String userId) async => loggedIn.add(userId);

  @override
  Future<void> logOut() async => logOutCalls++;

  @override
  Future<PremiumOffer> loadOffer() async {
    loadCalls++;
    if (loadFails) throw const PurchaseLoadException();
    return offer;
  }

  @override
  Future<PurchaseOutcome> purchase(PremiumPlan plan) async {
    purchased.add(plan);
    return purchaseOutcome;
  }

  @override
  Future<RestoreOutcome> restore() async {
    restoreCalls++;
    return restoreOutcome;
  }

  @override
  Future<String?> managementUrl() async {
    managementUrlCalls++;
    return url;
  }
}
```

- [ ] **Step 7: Conectar el arranque y la sesión**

En `nutrilife/lib/main.dart`, agregar el import:

```dart
import 'core/services/purchase_service.dart';
```

y en `main()`, justo antes de `final session = await SessionService.restore();`:

```dart
  await PurchaseService.instance.init();
```

En `nutrilife/lib/core/services/session_service.dart`, agregar el import:

```dart
import 'purchase_service.dart';
```

y un helper en la clase:

```dart
  // Ata las compras de RevenueCat a la cuenta de NutriLife, no al teléfono.
  static Future<void> _linkPurchases(Map<String, dynamic> user) async {
    final id = user['id']?.toString().trim();
    if (id != null && id.isNotEmpty) await PurchaseService.instance.logIn(id);
  }
```

- En `save`, después de `DioClient.authToken = token;`: `await _linkPurchases(user);`
- En `restore`, después de `DioClient.authToken = token;` (dentro del `try`): `await _linkPurchases(decodedUser);`
- En `clear`, después de `DioClient.authToken = null;`: `await PurchaseService.instance.logOut();`

(En las pruebas no hay key, así que `RevenueCatPurchaseService` no llama al plugin.)

- [ ] **Step 8: Correr toda la suite y compilar Android**

Run: `cd nutrilife && flutter test`
Expected: PASS.

Run: `cd nutrilife && flutter build apk --debug --dart-define=REVENUECAT_ANDROID_KEY=test_uRGxIRkhvDiFbCFREVZpGcvxgQN`
Expected: compila. Si falla por `minSdk`, poner en `android/app/build.gradle.kts` el mínimo que pida el error en lugar de `flutter.minSdkVersion`. La `MainActivity` ya usa `launchMode="singleTop"`, que es lo que pide RevenueCat.

- [ ] **Step 9: Commit (sin push hasta que el usuario diga)**

```bash
git add nutrilife/pubspec.yaml nutrilife/pubspec.lock nutrilife/lib/core/services/purchase_service.dart nutrilife/lib/main.dart nutrilife/lib/core/services/session_service.dart nutrilife/test/helpers/fake_purchase_service.dart nutrilife/test/core/services/purchase_offer_test.dart
git commit -m "feat(app): servicio de compras con RevenueCat atado a la sesión"
```

(Si `flutter pub add` cambió archivos generados de plugins de iOS/macOS/Windows, agregarlos también; **no** incluir el `GeneratedPluginRegistrant.swift` de macOS si ya estaba modificado antes de empezar, a menos que el cambio venga de este paso.)

---

### Task 8: Repositorio del sync y `proSource` en el perfil de la app

**Files:**
- Create: `nutrilife/lib/features/premium/data/subscription_repository.dart`
- Modify: `nutrilife/lib/core/network/api_routes.dart`
- Modify: `nutrilife/lib/features/profile/data/profile_repository.dart`
- Test: `nutrilife/test/features/premium/subscription_repository_test.dart`, `nutrilife/test/features/profile/profile_pro_test.dart`

**Interfaces:**
- Produces: `class SubscriptionState { String plan; DateTime? proUntil; String? proSource; }`, `class SubscriptionSyncException`, `class SubscriptionRepository { SubscriptionRepository({Dio? dio}); Future<SubscriptionState> sync(); }`, `ApiRoutes.subscriptionSync = '/subscription/sync'`.
- Produces: `UserProfile.proSource` (`String?`) y `UserProfile.hasStoreSubscription` (`bool`).

- [ ] **Step 1: Escribir las pruebas**

`nutrilife/test/features/premium/subscription_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/premium/data/subscription_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Map<String, Object?> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

SubscriptionRepository _repo(_Adapter adapter) =>
    SubscriptionRepository(dio: Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter);

void main() {
  test('sync devuelve el plan efectivo', () async {
    final adapter = _Adapter(200, {
      'success': true,
      'data': {'plan': 'PRO', 'proUntil': '2026-11-17T16:00:00.000Z', 'proSource': 'store'},
    });

    final state = await _repo(adapter).sync();

    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/subscription/sync');
    expect(state.plan, 'PRO');
    expect(state.proSource, 'store');
    expect(state.proUntil, DateTime.utc(2026, 11, 17, 16).toLocal());
  });

  test('un 502 lanza SubscriptionSyncException', () async {
    final adapter = _Adapter(502, {'success': false, 'message': 'x'});

    expect(_repo(adapter).sync(), throwsA(isA<SubscriptionSyncException>()));
  });
}
```

En `nutrilife/test/features/profile/profile_pro_test.dart`, cambiar `_profileJson` para aceptar `proSource`:

```dart
Map<String, Object?> _profileJson({required String plan, String? proUntil, String? proSource}) => {
      'name': 'Ana',
      'email': 'ana@test.com',
      'age': 30,
      'weight': 70,
      'height': 170,
      'goal': 'Perder peso',
      'plan': plan,
      'proUntil': proUntil,
      'proSource': proSource,
      'createdAt': '2024-05-01T00:00:00.000Z',
      'hasPassword': true,
    };
```

y agregar dentro de `main()`:

```dart
  test('lee proSource del perfil', () {
    final store = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'store'));
    final both = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'both'));
    final gift = UserProfile.fromJson(_profileJson(plan: 'PRO', proSource: 'gift'));

    expect(store.proSource, 'store');
    expect(store.hasStoreSubscription, isTrue);
    expect(both.hasStoreSubscription, isTrue);
    expect(gift.hasStoreSubscription, isFalse);
  });
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `cd nutrilife && flutter test test/features/premium/subscription_repository_test.dart test/features/profile/profile_pro_test.dart`
Expected: FAIL (no existe el repositorio; `UserProfile` no tiene `proSource`).

- [ ] **Step 3: Implementar**

En `nutrilife/lib/core/network/api_routes.dart`, al final de la clase:

```dart
  static const String subscriptionSync = '/subscription/sync';
```

`nutrilife/lib/features/premium/data/subscription_repository.dart`:

```dart
import 'package:dio/dio.dart';

import '../../../core/network/api_routes.dart';
import '../../../core/network/dio_client.dart';

/// Plan del usuario según el backend, después de leer RevenueCat.
class SubscriptionState {
  const SubscriptionState({required this.plan, this.proUntil, this.proSource});

  factory SubscriptionState.fromJson(Map<String, dynamic> json) => SubscriptionState(
        plan: json['plan']?.toString() ?? 'FREE',
        proUntil: DateTime.tryParse(json['proUntil']?.toString() ?? '')?.toLocal(),
        proSource: json['proSource']?.toString(),
      );

  final String plan;
  final DateTime? proUntil;
  final String? proSource;
}

/// El backend no pudo confirmar la compra todavía. El webhook la arregla.
class SubscriptionSyncException implements Exception {
  const SubscriptionSyncException();
}

class SubscriptionRepository {
  SubscriptionRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<SubscriptionState> sync() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiRoutes.subscriptionSync);
      final body = response.data;
      final data = body?['data'];
      if (body?['success'] == true && data is Map) {
        return SubscriptionState.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Cualquier fallo es lo mismo para quien compra: el PRO llega después.
    }
    throw const SubscriptionSyncException();
  }
}
```

En `nutrilife/lib/features/profile/data/profile_repository.dart`, en `UserProfile`:
- Agregar al constructor `this.proSource,`.
- Agregar el campo y el getter, debajo de `proUntil`:

```dart
  /// De dónde viene el PRO: 'gift', 'store', 'both' o null.
  final String? proSource;

  bool get hasStoreSubscription => proSource == 'store' || proSource == 'both';
```

- En `fromJson`: `proSource: json['proSource']?.toString(),`
- En `copyWith`: parámetro `String? proSource,` y `proSource: proSource ?? this.proSource,`.
- Cambiar el comentario de `proUntil` a `/// Fin del PRO, en hora local. Null con PRO = sin vencimiento.`

- [ ] **Step 4: Correr y ver que pasan**

Run: `cd nutrilife && flutter test test/features/premium/subscription_repository_test.dart test/features/profile/profile_pro_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add nutrilife/lib/core/network/api_routes.dart nutrilife/lib/features/premium/data/subscription_repository.dart nutrilife/lib/features/profile/data/profile_repository.dart nutrilife/test/features/premium/subscription_repository_test.dart nutrilife/test/features/profile/profile_pro_test.dart
git commit -m "feat(app): sync de la suscripción y proSource en el perfil"
```

---

### Task 9: Pantalla premium conectada a RevenueCat

**Files:**
- Modify: `nutrilife/lib/features/premium/presentation/screens/premium_screen.dart`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb` (+ `flutter gen-l10n`)
- Test: `nutrilife/test/features/premium/premium_screen_test.dart`

**Interfaces:**
- Consumes: `PurchaseService`, `PremiumOffer`, `PremiumPlan`, `PurchaseOutcome`, `RestoreOutcome`, `PurchaseLoadException` (Task 7); `SubscriptionRepository`, `SubscriptionSyncException` (Task 8); `AdsService.instance.setPlan(String?)`.
- Produces: `PremiumScreen({Key? key, PurchaseService? purchases, SubscriptionRepository? subscriptions})`. Hace `Navigator.pop(context, true)` cuando el usuario queda PRO (compra o restauración), para que quien la abrió recargue.

- [ ] **Step 1: Textos ARB**

En `nutrilife/lib/l10n/app_es.arb`:
- Reemplazar `"premiumSaveBadge": "Ahorra 50%",` por:

```json
  "premiumSaveBadge": "Ahorra {percent}%",
  "@premiumSaveBadge": {
    "placeholders": {
      "percent": {
        "type": "int"
      }
    }
  },
```

- Reemplazar `"premiumStartTrial": "Empezar 7 días gratis",` por `"premiumSubscribe": "Suscribirme",`.
- Después de `"premiumPaymentsSoon": "Los pagos llegan pronto",` agregar:

```json
  "premiumPrivacy": "Privacidad",
  "premiumLoadError": "No pudimos cargar los precios.",
  "premiumWelcome": "¡Ya eres PRO!",
  "premiumRestored": "Recuperamos tu PRO.",
  "premiumRestoreNone": "No encontramos compras para restaurar.",
  "premiumSyncDelayed": "Tu compra se registró. El PRO puede tardar unos minutos en activarse.",
  "premiumPending": "Tu pago está pendiente. El PRO se activa cuando la tienda lo confirme.",
  "premiumAlreadyOwned": "Ya tienes esta suscripción. Toca \"Restaurar compras\".",
  "premiumNotAllowed": "Este dispositivo no permite compras.",
  "premiumStoreUnavailable": "La tienda no está disponible ahora. Intenta más tarde.",
  "premiumPurchaseError": "No se pudo completar la compra. Intenta de nuevo.",
  "premiumAutoRenewNote": "La suscripción se renueva automáticamente. Puedes cancelarla cuando quieras desde la tienda.",
```

En `nutrilife/lib/l10n/app_en.arb`, los mismos cambios:
- `"premiumSaveBadge": "Save {percent}%",` con el mismo bloque `@premiumSaveBadge`.
- `"premiumSubscribe": "Subscribe",` en lugar de `premiumStartTrial`.
- Después de `premiumPaymentsSoon`:

```json
  "premiumPrivacy": "Privacy",
  "premiumLoadError": "We couldn't load the prices.",
  "premiumWelcome": "You're PRO now!",
  "premiumRestored": "We restored your PRO.",
  "premiumRestoreNone": "We didn't find any purchases to restore.",
  "premiumSyncDelayed": "Your purchase went through. PRO may take a few minutes to activate.",
  "premiumPending": "Your payment is pending. PRO activates once the store confirms it.",
  "premiumAlreadyOwned": "You already have this subscription. Tap \"Restore purchases\".",
  "premiumNotAllowed": "This device doesn't allow purchases.",
  "premiumStoreUnavailable": "The store isn't available right now. Try again later.",
  "premiumPurchaseError": "We couldn't complete the purchase. Try again.",
  "premiumAutoRenewNote": "Your subscription renews automatically. Cancel anytime from the store.",
```

Run: `cd nutrilife && flutter gen-l10n`
Expected: regenera `lib/l10n/app_localizations*.dart` sin errores. Revisar con `grep -rn "premiumStartTrial\|premiumSaveBadge" lib test` que no quede uso viejo fuera de `premium_screen.dart` y su prueba (se cambian abajo).

- [ ] **Step 2: Reescribir las pruebas de la pantalla**

`nutrilife/test/features/premium/premium_screen_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/services/purchase_service.dart';
import 'package:nutrilife/features/premium/data/subscription_repository.dart';
import 'package:nutrilife/features/premium/presentation/screens/premium_screen.dart';

import '../../helpers/fake_purchase_service.dart';
import '../../helpers/l10n_app.dart';

class _FakeSubscriptions extends SubscriptionRepository {
  _FakeSubscriptions({this.fails = false}) : super(dio: Dio());

  final bool fails;
  int calls = 0;

  @override
  Future<SubscriptionState> sync() async {
    calls++;
    if (fails) throw const SubscriptionSyncException();
    return const SubscriptionState(plan: 'PRO', proSource: 'store');
  }
}

/// Abre la pantalla desde un botón para poder ver el pop con resultado.
Future<List<Object?>> _pump(
  WidgetTester tester, {
  required FakePurchaseService purchases,
  _FakeSubscriptions? subscriptions,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final results = <Object?>[];
  await tester.pumpWidget(l10nApp(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          results.add(await Navigator.of(context).push<bool>(MaterialPageRoute(
            builder: (_) => PremiumScreen(purchases: purchases, subscriptions: subscriptions ?? _FakeSubscriptions()),
          )));
        },
        child: const Text('abrir'),
      ),
    ),
  )));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('muestra los precios de la tienda y el ahorro', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(find.text('\$29.99 / año'), findsOneWidget);
    expect(find.text('\$4.99 / mes'), findsOneWidget);
    expect(find.text('Ahorra 50%'), findsOneWidget);
  });

  testWidgets('el anual viene elegido y se puede cambiar', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(find.byKey(const ValueKey('plan-yearly-selected')), findsOneWidget);
    await tester.tap(find.text('Mensual'));
    await tester.pump();
    expect(find.byKey(const ValueKey('plan-monthly-selected')), findsOneWidget);
  });

  testWidgets('si fallan los precios se puede reintentar', (tester) async {
    final purchases = FakePurchaseService(loadFails: true);
    await _pump(tester, purchases: purchases);

    expect(find.text('No pudimos cargar los precios.'), findsOneWidget);
    purchases.loadFails = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('\$29.99 / año'), findsOneWidget);
    expect(purchases.loadCalls, 2);
  });

  testWidgets('comprar con éxito sincroniza y cierra con true', (tester) async {
    final purchases = FakePurchaseService();
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(tester, purchases: purchases, subscriptions: subscriptions);

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(purchases.purchased, [PremiumPlan.yearly]);
    expect(subscriptions.calls, 1);
    expect(results, [true]);
    expect(find.text('¡Ya eres PRO!'), findsOneWidget);
  });

  testWidgets('si el sync falla avisa que tarda y cierra igual', (tester) async {
    final results = await _pump(tester, purchases: FakePurchaseService(), subscriptions: _FakeSubscriptions(fails: true));

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.text('Tu compra se registró. El PRO puede tardar unos minutos en activarse.'), findsOneWidget);
  });

  testWidgets('cancelar la compra no hace nada', (tester) async {
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(
      tester,
      purchases: FakePurchaseService(purchaseOutcome: PurchaseOutcome.cancelled),
      subscriptions: subscriptions,
    );

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(subscriptions.calls, 0);
    expect(results, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('pago pendiente avisa y no cierra', (tester) async {
    final results = await _pump(tester, purchases: FakePurchaseService(purchaseOutcome: PurchaseOutcome.pending));

    await tester.tap(find.text('Suscribirme'));
    await tester.pumpAndSettle();

    expect(results, isEmpty);
    expect(find.text('Tu pago está pendiente. El PRO se activa cuando la tienda lo confirme.'), findsOneWidget);
  });

  testWidgets('restaurar sin compras avisa', (tester) async {
    final purchases = FakePurchaseService(restoreOutcome: RestoreOutcome.nothingFound);
    final results = await _pump(tester, purchases: purchases);

    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(purchases.restoreCalls, 1);
    expect(results, isEmpty);
    expect(find.text('No encontramos compras para restaurar.'), findsOneWidget);
  });

  testWidgets('restaurar con éxito sincroniza y cierra', (tester) async {
    final subscriptions = _FakeSubscriptions();
    final results = await _pump(tester, purchases: FakePurchaseService(), subscriptions: subscriptions);

    await tester.tap(find.text('Restaurar compras'));
    await tester.pumpAndSettle();

    expect(subscriptions.calls, 1);
    expect(results, [true]);
    expect(find.text('Recuperamos tu PRO.'), findsOneWidget);
  });

  testWidgets('sin key los pagos llegan pronto', (tester) async {
    final purchases = FakePurchaseService(isEnabled: false);
    await _pump(tester, purchases: purchases);

    expect(purchases.loadCalls, 0);
    await tester.tap(find.text('Suscribirme'));
    await tester.pump();
    expect(find.text('Los pagos llegan pronto'), findsOneWidget);
  });

  testWidgets('muestra el aviso de renovación automática', (tester) async {
    await _pump(tester, purchases: FakePurchaseService());

    expect(
      find.text('La suscripción se renueva automáticamente. Puedes cancelarla cuando quieras desde la tienda.'),
      findsOneWidget,
    );
    expect(find.text('Privacidad'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Correr y ver que fallan**

Run: `cd nutrilife && flutter test test/features/premium/premium_screen_test.dart`
Expected: FAIL (la pantalla no acepta `purchases` ni `subscriptions`).

- [ ] **Step 4: Reescribir la pantalla**

En `nutrilife/lib/features/premium/presentation/screens/premium_screen.dart`, reemplazar todo desde los imports hasta el final de `_PremiumScreenState` (la clase `_PlanCard` se queda, con el cambio de abajo) por:

```dart
import 'package:flutter/material.dart';
import '../../../legal/data/legal_documents.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';
import '../../data/subscription_repository.dart';
import '../../../../core/ads/ads_service.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/theme/app_theme.dart';

List<String> premiumBenefits(AppLocalizations l10n) => [
      l10n.premiumBenefitChat,
      l10n.premiumBenefitProgress,
      l10n.premiumBenefitPlans,
      l10n.premiumBenefitRecipes,
    ];

/// Pantalla de compra del PRO. Cierra con `true` cuando el usuario queda PRO.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.purchases, this.subscriptions});

  final PurchaseService? purchases;
  final SubscriptionRepository? subscriptions;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final PurchaseService _purchases = widget.purchases ?? PurchaseService.instance;
  late final SubscriptionRepository _subscriptions = widget.subscriptions ?? SubscriptionRepository();

  PremiumPlan _plan = PremiumPlan.yearly;
  PremiumOffer? _offer;
  bool _loading = false;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_purchases.isEnabled) _loadOffer();
  }

  Future<void> _loadOffer() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final offer = await _purchases.loadOffer();
      if (!mounted) return;
      setState(() => _offer = offer);
    } on PurchaseLoadException {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _subscribe() async {
    final l10n = context.l10n;
    if (!_purchases.isEnabled) return _say(l10n.premiumPaymentsSoon);

    setState(() => _busy = true);
    final outcome = await _purchases.purchase(_plan);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case PurchaseOutcome.success:
        await _activate(l10n.premiumWelcome);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        _say(l10n.premiumPending);
      case PurchaseOutcome.alreadyOwned:
        _say(l10n.premiumAlreadyOwned);
      case PurchaseOutcome.notAllowed:
        _say(l10n.premiumNotAllowed);
      case PurchaseOutcome.storeUnavailable:
        _say(l10n.premiumStoreUnavailable);
      case PurchaseOutcome.failed:
        _say(l10n.premiumPurchaseError);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    if (!_purchases.isEnabled) return _say(l10n.premiumPaymentsSoon);

    setState(() => _busy = true);
    final outcome = await _purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case RestoreOutcome.restored:
        await _activate(l10n.premiumRestored);
      case RestoreOutcome.nothingFound:
        _say(l10n.premiumRestoreNone);
      case RestoreOutcome.failed:
        _say(l10n.premiumStoreUnavailable);
    }
  }

  // La tienda ya cobró: se le avisa al backend y se cierra. Si el backend no
  // responde, el webhook de RevenueCat activa el PRO después.
  Future<void> _activate(String successMessage) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    var message = successMessage;
    try {
      final state = await _subscriptions.sync();
      AdsService.instance.setPlan(state.plan);
    } on SubscriptionSyncException {
      message = l10n.premiumSyncDelayed;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _say(message);
    Navigator.of(context).pop(true);
  }

  String? _priceText(PremiumPlan plan) {
    final price = _offer?.priceOf(plan)?.priceString;
    if (price == null) return null;
    final l10n = context.l10n;
    return plan == PremiumPlan.yearly ? l10n.premiumPricePerYear(price) : l10n.premiumPricePerMonth(price);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savings = _offer?.yearlySavingsPercent;
    final canBuy = !_busy && (!_purchases.isEnabled || (_offer?.priceOf(_plan) != null));
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
              child: Image.asset('assets/images/nutria_atenta.png', width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premiumTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final benefit in premiumBenefits(l10n))
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
            title: l10n.premiumPlanYearly,
            price: _priceText(PremiumPlan.yearly),
            loading: _loading,
            badge: savings == null ? null : l10n.premiumSaveBadge(savings),
            selected: _plan == PremiumPlan.yearly,
            selectedKey: const ValueKey('plan-yearly-selected'),
            onTap: () => setState(() => _plan = PremiumPlan.yearly),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: l10n.premiumPlanMonthly,
            price: _priceText(PremiumPlan.monthly),
            loading: _loading,
            selected: _plan == PremiumPlan.monthly,
            selectedKey: const ValueKey('plan-monthly-selected'),
            onTap: () => setState(() => _plan = PremiumPlan.monthly),
          ),
          if (_loadFailed) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(l10n.premiumLoadError, style: const TextStyle(color: AppTheme.onSurfaceVariant))),
                TextButton(onPressed: _loadOffer, child: Text(l10n.commonRetry)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: canBuy ? _subscribe : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(l10n.premiumSubscribe),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.premiumAutoRenewNote,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: _busy ? null : _restore, child: Text(l10n.premiumRestore)),
              const Text('·'),
              TextButton(
                onPressed: () => openLegalDocument(context, LegalDocuments.terms),
                child: Text(l10n.premiumTerms),
              ),
              const Text('·'),
              TextButton(
                onPressed: () => openLegalDocument(context, LegalDocuments.privacy),
                child: Text(l10n.premiumPrivacy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

En `_PlanCard`:
- `final String price;` → `final String? price;` y agregar `final bool loading;`.
- Constructor: `required this.price,` → `this.price,` y agregar `this.loading = false,`.
- Reemplazar `Text(price, style: const TextStyle(color: AppTheme.onSurfaceVariant)),` por:

```dart
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (price != null)
                    Text(price!, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
```

- [ ] **Step 5: Correr y ver que pasan**

Run: `cd nutrilife && flutter test test/features/premium/premium_screen_test.dart`
Expected: PASS (11 pruebas).

Run: `cd nutrilife && flutter test`
Expected: PASS (si alguna prueba de l10n compara la lista de claves ARB, actualizarla con las claves nuevas).

- [ ] **Step 6: Commit**

```bash
git add nutrilife/lib/features/premium/presentation/screens/premium_screen.dart nutrilife/lib/l10n nutrilife/test/features/premium/premium_screen_test.dart
git commit -m "feat(app): pantalla premium cobra con RevenueCat"
```

---

### Task 10: Perfil con "Administrar suscripción" y recarga después de comprar

**Files:**
- Modify: `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart`
- Modify: `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart:54-58`
- Modify: `nutrilife/lib/l10n/app_es.arb`, `nutrilife/lib/l10n/app_en.arb` (+ `flutter gen-l10n`)
- Test: `nutrilife/test/features/profile/profile_pro_test.dart`

**Interfaces:**
- Consumes: `UserProfile.hasStoreSubscription` (Task 8), `PurchaseService.managementUrl()` (Task 7), `PremiumScreen` que cierra con `true` (Task 9).
- Produces: `ProfileScreen({..., PurchaseService? purchases})`.

- [ ] **Step 1: Texto ARB**

En `app_es.arb`, después de `"profilePremiumActiveForever": ...,`:

```json
  "profilePremiumManageUnavailable": "Administra tu suscripción desde la tienda de tu teléfono.",
```

En `app_en.arb`, en el mismo lugar:

```json
  "profilePremiumManageUnavailable": "Manage your subscription from your phone's app store.",
```

Run: `cd nutrilife && flutter gen-l10n`

- [ ] **Step 2: Escribir las pruebas**

En `nutrilife/test/features/profile/profile_pro_test.dart`:
- Importar el servicio falso: `import '../../helpers/fake_purchase_service.dart';`
- Cambiar `_pumpProfile` para recibir el servicio:

```dart
Future<void> _pumpProfile(
  WidgetTester tester,
  Map<String, Object?> profile, {
  Locale locale = const Locale('es'),
  FakePurchaseService? purchases,
}) async {
```

  y pasarle `purchases: purchases ?? FakePurchaseService(),` al `ProfileScreen(...)`.
- Agregar al final de `main()`:

```dart
  testWidgets('PRO pagado: tocar la fila pide la página de la tienda', (tester) async {
    final purchases = FakePurchaseService(url: null);
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z', proSource: 'store'),
      purchases: purchases,
    );

    await tester.tap(find.text('Activo hasta el 24 nov 2026'));
    await tester.pump();

    expect(purchases.managementUrlCalls, 1);
    expect(find.text('Administra tu suscripción desde la tienda de tu teléfono.'), findsOneWidget);
  });

  testWidgets('PRO regalado: la fila no hace nada', (tester) async {
    final purchases = FakePurchaseService();
    await _pumpProfile(
      tester,
      _profileJson(plan: 'PRO', proUntil: '2026-11-24T12:00:00.000Z', proSource: 'gift'),
      purchases: purchases,
    );

    await tester.tap(find.text('Activo hasta el 24 nov 2026'));
    await tester.pump();

    expect(purchases.managementUrlCalls, 0);
  });
```

- [ ] **Step 3: Correr y ver que fallan**

Run: `cd nutrilife && flutter test test/features/profile/profile_pro_test.dart`
Expected: FAIL (`ProfileScreen` no acepta `purchases`).

- [ ] **Step 4: Implementar el perfil**

En `nutrilife/lib/features/profile/presentation/screens/profile_screen.dart`:

- Imports nuevos:

```dart
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/purchase_service.dart';
```

- En `ProfileScreen`: parámetro `this.purchases,` en el constructor y campo `final PurchaseService? purchases;`.
- En `_ProfileScreenState`, agregar:

```dart
  late final PurchaseService _purchases = widget.purchases ?? PurchaseService.instance;

  Future<void> _openPremium() async {
    final becamePro = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    if (becamePro == true && mounted) await _refreshProfile();
  }

  // Cancelar o cambiar de plan se hace en la tienda, no en la app.
  Future<void> _manageSubscription() async {
    final url = await _purchases.managementUrl();
    if (!mounted) return;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.profilePremiumManageUnavailable)));
    }
  }
```

- En la llamada `_SettingsCard(`, agregar:

```dart
                  hasStoreSubscription: profile.hasStoreSubscription,
                  onOpenPremium: _openPremium,
                  onManageSubscription: _manageSubscription,
```

- En `_SettingsCard`: agregar al constructor `required this.hasStoreSubscription, required this.onOpenPremium, required this.onManageSubscription,` y los campos:

```dart
  /// El PRO viene (también) de la tienda: la fila abre la página para administrarla.
  final bool hasStoreSubscription;
  final VoidCallback onOpenPremium;
  final VoidCallback onManageSubscription;
```

  Cambiar el comentario de `proUntil` a `/// Fin del PRO. Null con PRO = sin vencimiento.`
- En la fila PRO, reemplazar `trailing:` y `onTap:` por:

```dart
            trailing: isPro && !hasStoreSubscription
                ? const Icon(Icons.check_circle_rounded, color: _ProfileColors.green, size: 26)
                : const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB4BC), size: 30),
            onTap: !isPro
                ? onOpenPremium
                : hasStoreSubscription
                    ? onManageSubscription
                    : null,
```

(`launchUrl` en una prueba sin plugin no se llama: con `url: null` el servicio falso devuelve `null` y se muestra el aviso.)

- [ ] **Step 5: Chat recarga la cuota después de comprar**

En `nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart`, reemplazar `_openPremium` por:

```dart
  Future<void> _openPremium() async {
    final becamePro = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    if (becamePro == true) unawaited(_viewModel.loadQuota());
  }
```

(Revisar que quien la llama siga compilando: si se pasa como `VoidCallback`, `() => _openPremium()` o el tear-off `_openPremium` sirven igual porque el resultado se ignora.)

- [ ] **Step 6: Correr y ver que pasan**

Run: `cd nutrilife && flutter test`
Expected: PASS.

Run: `cd nutrilife && flutter analyze`
Expected: sin errores nuevos.

- [ ] **Step 7: Commit**

```bash
git add nutrilife/lib/features/profile/presentation/screens/profile_screen.dart nutrilife/lib/features/chatbot/presentation/screens/ai_chat_view.dart nutrilife/lib/l10n nutrilife/test/features/profile/profile_pro_test.dart
git commit -m "feat(app): administrar la suscripción desde el perfil y recargar al comprar"
```

---

### Task 11: Configuración, despliegue y prueba manual

Esta tarea la hacen el usuario y Claude juntos. Claude no aplica migraciones a producción ni toca Dokploy ni RevenueCat sin que el usuario lo confirme.

- [ ] **Step 1: Migración (antes de pushear el backend de Task 5)**

El usuario corre (primero sin `--yes` para ver contra qué base va):

```bash
cd backend && npm run db:apply -- update_17_10_2026_store_subscriptions.sql
```

```bash
cd backend && npm run db:apply -- update_17_10_2026_store_subscriptions.sql --yes
```

Después, `git push origin main` del backend (Task 5, paso 6).

- [ ] **Step 2: Variables en Dokploy**

El usuario agrega en el servicio del backend:
- `REVENUECAT_SECRET_KEY` = secret API key v1 del proyecto (RevenueCat → Project settings → API keys).
- `REVENUECAT_WEBHOOK_AUTH` = un valor largo al azar (por ejemplo, la salida de `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`).
- `REVENUECAT_ALLOW_SANDBOX` = `true`.

Y redespliega.

- [ ] **Step 3: RevenueCat**

El usuario configura:
1. Entitlement `nutrilife_pro` con los productos `monthly` y `yearly` de la Test Store.
2. Offering `default`, marcado como *current*, con los paquetes Monthly (`$rc_monthly`) y Annual (`$rc_annual`).
3. Integrations → Webhooks: URL `https://<backend>/api/v1/subscription/webhook`, Authorization header = el mismo `REVENUECAT_WEBHOOK_AUTH`. Botón "Send test event" → debe responder 200.

- [ ] **Step 4: Lanzar la app en el emulador**

Claude la lanza (el usuario hace la prueba):

```bash
cd nutrilife && flutter run --dart-define=REVENUECAT_ANDROID_KEY=test_uRGxIRkhvDiFbCFREVZpGcvxgQN --dart-define=REVENUECAT_IOS_KEY=test_uRGxIRkhvDiFbCFREVZpGcvxgQN
```

El usuario comprueba:
1. La pantalla premium muestra los precios de la Test Store.
2. Comprar el mensual → "¡Ya eres PRO!", el perfil dice "Activo hasta …" y el Chef IA deja de mostrar el límite FREE.
3. En el panel admin, el usuario aparece "Pagado: monthly en Test Store".
4. Cerrar sesión, entrar de nuevo, "Restaurar compras" → vuelve el PRO.
5. Expirar o cancelar desde RevenueCat → al vencer (más la hora de margen) vuelve a FREE.

- [ ] **Step 5: Pushear app y panel**

Con la prueba manual bien, preguntar al usuario si pushear los commits de `nutrilife/` y `admin-panel/`.

- [ ] **Step 6: Memoria**

Actualizar `free-pro-limits-status.md` en la memoria: parte 5 implementada y lo pendiente (cuentas de las tiendas, keys reales, `REVENUECAT_ALLOW_SANDBOX=false`).
