import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { AppError } = await import(src('utils/AppError.js'));

const REPO_EXPORTS = [
  'findExistingUserIds',
  'findStoreRenewalsDue',
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

const { handleWebhookEvent, renewDueStoreSubscriptions, saveGift, syncUser, webhookUserIds } = await import(
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
  repo.findStoreRenewalsDue = async () => [];
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

test('webhook: ids fuera de int4 o cero se descartan', () => {
  assert.deepEqual(webhookUserIds({ app_user_id: '99999999999' }), []);
  assert.deepEqual(webhookUserIds({ app_user_id: '0' }), []);
  assert.deepEqual(webhookUserIds({ app_user_id: '2147483647' }), [2147483647]);
});

test('webhook: transferred_from/to solo se leen si son arreglos', () => {
  assert.deepEqual(webhookUserIds({ type: 'TRANSFER', transferred_from: '7', transferred_to: ['9'] }), [9]);
  assert.deepEqual(webhookUserIds({ type: 'TRANSFER', transferred_from: ['7'], transferred_to: '9' }), [7]);
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

// Los fallos de RevenueCat se registran: se silencian para no ensuciar la salida.
const quietly = async (fn) => {
  const original = console.error;
  console.error = () => {};
  try {
    return await fn();
  } finally {
    console.error = original;
  }
};

const failFor = (failing) => async (id) => {
  if (failing.includes(Number(id))) throw new AppError('x', 502, 'SUBSCRIPTION_PROVIDER_ERROR');
  return activeSubscriber();
};

test('renovaciones: pide los pendientes con la ventana y el tope', async () => {
  let asked;
  repo.findStoreRenewalsDue = async (options) => {
    asked = options;
    return [];
  };

  assert.deepEqual(await renewDueStoreSubscriptions(), { checked: 0, failed: 0, stopped: false });
  assert.deepEqual(asked, { lookaheadMs: 15 * 60 * 1000, waitMs: 3 * 24 * 60 * 60 * 1000, limit: 100 });
});

test('renovaciones: sincroniza a cada pendiente con RevenueCat', async () => {
  repo.findStoreRenewalsDue = async () => [3, 8];
  const synced = [];
  subscriberImpl = async (id) => {
    synced.push(id);
    return activeSubscriber();
  };

  assert.deepEqual(await renewDueStoreSubscriptions(), { checked: 2, failed: 0, stopped: false });
  assert.deepEqual(synced, ['3', '8']);
  assert.deepEqual(
    calls.filter(([kind]) => kind === 'plan').map(([, userId]) => userId),
    [3, 8]
  );
});

test('renovaciones: un fallo suelto no detiene a los demás', async () => {
  repo.findStoreRenewalsDue = async () => [1, 2, 3];
  subscriberImpl = failFor([2]);

  const result = await quietly(() => renewDueStoreSubscriptions());

  assert.deepEqual(result, { checked: 3, failed: 1, stopped: false });
  assert.deepEqual(
    calls.filter(([kind]) => kind === 'plan').map(([, userId]) => userId),
    [1, 3]
  );
});

test('renovaciones: 3 fallos seguidos dejan al resto para el próximo barrido', async () => {
  repo.findStoreRenewalsDue = async () => [1, 2, 3, 4, 5];
  const asked = [];
  subscriberImpl = async (id) => {
    asked.push(Number(id));
    throw new AppError('x', 502, 'SUBSCRIPTION_PROVIDER_ERROR');
  };

  const result = await quietly(() => renewDueStoreSubscriptions());

  assert.deepEqual(result, { checked: 3, failed: 3, stopped: true });
  assert.deepEqual(asked, [1, 2, 3]);
  assert.equal(calls.length, 0);
});

test('renovaciones: un sync bueno reinicia la cuenta de fallos', async () => {
  repo.findStoreRenewalsDue = async () => [1, 2, 3, 4, 5, 6];
  subscriberImpl = failFor([1, 2, 4, 5]);

  const result = await quietly(() => renewDueStoreSubscriptions());

  assert.deepEqual(result, { checked: 6, failed: 4, stopped: false });
});

test('renovaciones: si no se pueden leer los pendientes no lanza', async () => {
  repo.findStoreRenewalsDue = async () => {
    throw new Error('db caída');
  };

  const result = await quietly(() => renewDueStoreSubscriptions());

  assert.deepEqual(result, { checked: 0, failed: 0, stopped: false });
});
