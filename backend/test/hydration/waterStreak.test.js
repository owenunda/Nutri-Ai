import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  addDays,
  bestStreak,
  currentStreak,
  dayInTimeZone,
  summarizeWater,
} from '../../src/modules/hydration/waterStreak.js';

test('addDays cruza meses y años bisiestos', () => {
  assert.equal(addDays('2026-10-31', 1), '2026-11-01');
  assert.equal(addDays('2028-03-01', -1), '2028-02-29');
  assert.equal(addDays('2027-01-01', -1), '2026-12-31');
});

test('dayInTimeZone usa la fecha de la zona, no la UTC', () => {
  // 03:00 UTC del 18 todavía es el 17 en Bogotá.
  assert.equal(dayInTimeZone(new Date('2026-10-18T03:00:00Z'), 'America/Bogota'), '2026-10-17');
  assert.equal(dayInTimeZone(new Date('2026-10-18T06:00:00Z'), 'America/Bogota'), '2026-10-18');
});

test('racha actual: cuenta hasta hoy si hoy ya se cumplió', () => {
  const history = { '2026-10-15': 4, '2026-10-16': 4, '2026-10-17': 4 };
  assert.equal(currentStreak(history, '2026-10-17'), 3);
});

test('racha actual: hoy a medias no la corta, sigue desde ayer', () => {
  const history = { '2026-10-15': 4, '2026-10-16': 4, '2026-10-17': 2 };
  assert.equal(currentStreak(history, '2026-10-17'), 2);
});

test('racha actual: si ayer no se cumplió, es 0', () => {
  const history = { '2026-10-14': 4, '2026-10-15': 4, '2026-10-16': 3 };
  assert.equal(currentStreak(history, '2026-10-17'), 0);
});

test('mejor racha: la más larga, aunque no sea la actual', () => {
  const history = {
    '2026-10-01': 4,
    '2026-10-02': 4,
    '2026-10-03': 4,
    '2026-10-04': 1,
    '2026-10-10': 4,
  };
  assert.equal(bestStreak(history), 3);
  assert.equal(bestStreak({}), 0);
});

test('resumen: totales, últimos 7 días y último día', () => {
  const history = { '2026-10-11': 2, '2026-10-16': 4, '2026-10-17': 3 };
  const summary = summarizeWater(history, '2026-10-17');

  assert.equal(summary.goal, 4);
  assert.equal(summary.today, '2026-10-17');
  assert.equal(summary.glassesToday, 3);
  assert.equal(summary.currentStreak, 1);
  assert.equal(summary.bestStreak, 1);
  assert.equal(summary.daysLogged, 3);
  assert.equal(summary.goalDays, 1);
  assert.equal(summary.totalGlasses, 9);
  assert.equal(summary.lastDay, '2026-10-17');
  assert.deepEqual(summary.lastSevenDays, [
    { day: '2026-10-11', glasses: 2 },
    { day: '2026-10-12', glasses: 0 },
    { day: '2026-10-13', glasses: 0 },
    { day: '2026-10-14', glasses: 0 },
    { day: '2026-10-15', glasses: 0 },
    { day: '2026-10-16', glasses: 4 },
    { day: '2026-10-17', glasses: 3 },
  ]);
});

test('resumen: un usuario que ya va un día por delante usa su propio hoy', () => {
  const history = { '2026-10-17': 4, '2026-10-18': 4 };
  const summary = summarizeWater(history, '2026-10-17');

  assert.equal(summary.today, '2026-10-18');
  assert.equal(summary.glassesToday, 4);
  assert.equal(summary.currentStreak, 2);
});

test('resumen: sin historial todo queda en cero', () => {
  const summary = summarizeWater({}, '2026-10-17');

  assert.equal(summary.currentStreak, 0);
  assert.equal(summary.bestStreak, 0);
  assert.equal(summary.daysLogged, 0);
  assert.equal(summary.lastDay, null);
  assert.equal(summary.lastSevenDays.length, 7);
});
