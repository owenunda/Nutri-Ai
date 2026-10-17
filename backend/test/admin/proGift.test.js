import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { PRO_DURATIONS, computeProUntil } = await import(src('modules/admin/proGift.js'));

const NOW = new Date('2026-10-17T15:00:00Z');
const iso = (date) => date?.toISOString() ?? null;

test('las duraciones son 7 días, 1, 3, 6 y 12 meses y sin vencimiento', () => {
  assert.deepEqual(Object.keys(PRO_DURATIONS), ['7d', '1m', '3m', '6m', '12m', 'forever']);
});

test('un FREE recibe 7 días desde ahora', () => {
  assert.equal(iso(computeProUntil({ plan: 'FREE', proUntil: null }, '7d', NOW)), '2026-10-24T15:00:00.000Z');
});

test('un FREE recibe 1 mes desde ahora', () => {
  assert.equal(iso(computeProUntil({ plan: 'FREE', proUntil: null }, '1m', NOW)), '2026-11-17T15:00:00.000Z');
});

test('12 meses es un año', () => {
  assert.equal(iso(computeProUntil({ plan: 'FREE', proUntil: null }, '12m', NOW)), '2027-10-17T15:00:00.000Z');
});

test('si ya es PRO con fecha, se suma a esa fecha', () => {
  const current = { plan: 'PRO', proUntil: new Date('2026-11-01T00:00:00Z') };
  assert.equal(iso(computeProUntil(current, '7d', NOW)), '2026-11-08T00:00:00.000Z');
});

test('si su PRO ya venció, cuenta desde ahora', () => {
  const current = { plan: 'PRO', proUntil: new Date('2026-10-01T00:00:00Z') };
  assert.equal(iso(computeProUntil(current, '7d', NOW)), '2026-10-24T15:00:00.000Z');
});

test('una fecha vieja de un FREE no se suma', () => {
  const current = { plan: 'FREE', proUntil: new Date('2026-12-01T00:00:00Z') };
  assert.equal(iso(computeProUntil(current, '7d', NOW)), '2026-10-24T15:00:00.000Z');
});

test('sin vencimiento es null', () => {
  assert.equal(computeProUntil({ plan: 'FREE', proUntil: null }, 'forever', NOW), null);
});

test('un PRO sin vencimiento lo conserva aunque le regalen días', () => {
  assert.equal(computeProUntil({ plan: 'PRO', proUntil: null }, '7d', NOW), null);
});

test('del 31 de enero, 1 mes cae en el último día de febrero', () => {
  const jan31 = new Date('2027-01-31T12:00:00Z');
  assert.equal(iso(computeProUntil({ plan: 'FREE', proUntil: null }, '1m', jan31)), '2027-02-28T12:00:00.000Z');
});

test('acepta la fecha guardada como texto ISO', () => {
  const current = { plan: 'PRO', proUntil: '2026-11-01T00:00:00.000Z' };
  assert.equal(iso(computeProUntil(current, '7d', NOW)), '2026-11-08T00:00:00.000Z');
});
