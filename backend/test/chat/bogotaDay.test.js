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
