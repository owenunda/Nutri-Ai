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
