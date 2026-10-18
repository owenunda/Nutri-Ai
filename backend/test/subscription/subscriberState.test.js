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
  assert.deepEqual(read(subscriber({ subscription: { store: 'play_store' } }), false), {
    productId: 'monthly',
    store: 'play_store',
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

test('la Test Store cuenta como sandbox aunque is_sandbox sea false', () => {
  const state = read(subscriber({ subscription: { store: 'test_store', is_sandbox: false } }), false);
  assert.equal(state.environment, 'sandbox');
  assert.equal(state.expiresAt, null);
});

test('sin sandbox permitido, un entitlement sin suscripción que lo respalde no da PRO', () => {
  const state = read(subscriber({ productKey: 'otro_producto', subscription: { store: 'play_store' } }), false);
  assert.equal(state.expiresAt, null);
});

test('con sandbox permitido, un entitlement sin suscripción conserva su vencimiento', () => {
  const state = read(subscriber({ productKey: 'otro_producto', subscription: { store: 'play_store' } }), true);
  assert.equal(state.expiresAt, '2026-11-17T15:00:00.000Z');
});

test('Play: encuentra la suscripción por el id base si la clave lleva el plan base', () => {
  const state = read(
    subscriber({ entitlement: { product_identifier: 'nutrilife_pro:monthly' }, productKey: 'nutrilife_pro', subscription: { store: 'play_store' } })
  );
  assert.equal(state.store, 'play_store');
  assert.equal(state.productId, 'nutrilife_pro:monthly');
});

test('un mapa de suscripciones null cuenta como vacío', () => {
  const state = read({
    entitlements: {
      nutrilife_pro: { expires_date: '2026-11-17T15:00:00Z', product_identifier: 'monthly' },
    },
    subscriptions: null,
  });
  assert.equal(state.store, null);
  assert.equal(state.expiresAt, '2026-11-17T15:00:00.000Z');
});
