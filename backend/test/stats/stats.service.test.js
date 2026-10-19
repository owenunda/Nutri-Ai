import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const repo = {};
mock.module(src('modules/stats/stats.repository.js'), {
  exports: {
    getUserNutritionalData: (...args) => repo.getUserNutritionalData(...args),
    getConsumptionCaloriesByDate: (...args) => repo.getConsumptionCaloriesByDate(...args),
    getDailyConsumptionRepository: (...args) => repo.getDailyConsumptionRepository(...args),
    getFirstMealDateRepository: (...args) => repo.getFirstMealDateRepository(...args),
  },
});

const { calculateDailyLimit, getCalorieStreakService, getWeekStatsService } = await import(
  src('modules/stats/stats.service.js')
);

// Perfil de prueba: meta de 'lose' para estos datos.
const ana = { userId: 7, age: 30, goal: 'lose', height: 165, weight: 70 };
const limit = calculateDailyLimit(ana);
const inRange = Math.round(limit * 0.9);

let requested;

beforeEach(() => {
  requested = null;
  repo.getUserNutritionalData = async () => ana;
  repo.getFirstMealDateRepository = async () => '2026-10-10';
  repo.getDailyConsumptionRepository = async (userId, start, end) => {
    requested = { userId, start, end };
    const days = [];
    for (let day = start; day <= end; ) {
      const n = Number(day.slice(8));
      // 10..13 en rango, 14 se pasó, 15..18 en rango.
      days.push({ date: day, totalConsumed: n === 14 ? limit * 2 : inRange });
      const next = new Date(`${day}T00:00:00Z`);
      next.setUTCDate(next.getUTCDate() + 1);
      day = next.toISOString().slice(0, 10);
    }
    return days;
  };
});

test('la racha usa toda la historia, desde la primera comida hasta hoy', async () => {
  const streak = await getCalorieStreakService(7, '2026-10-18');

  assert.deepEqual(requested, { userId: 7, start: '2026-10-10', end: '2026-10-18' });
  assert.equal(streak.current, 4);
  assert.equal(streak.best, 4);
  assert.equal(streak.dailyLimit, limit);
  assert.equal(streak.min, Math.round(limit * 0.7));
  assert.equal(streak.max, limit);
});

test('sin comidas registradas la racha es 0', async () => {
  repo.getFirstMealDateRepository = async () => null;
  const streak = await getCalorieStreakService(7, '2026-10-18');
  assert.equal(streak.current, 0);
  assert.equal(streak.best, 0);
  assert.equal(requested, null);
});

test('sin datos físicos no hay meta ni racha', async () => {
  repo.getUserNutritionalData = async () => ({ ...ana, age: null });
  const streak = await getCalorieStreakService(7, '2026-10-18');
  assert.deepEqual(streak, { current: null, best: null, dailyLimit: null, min: null, max: null });
});

test('usuario inexistente da 404', async () => {
  repo.getUserNutritionalData = async () => null;
  await assert.rejects(getCalorieStreakService(7, '2026-10-18'), { status: 404, code: 'USER_NOT_FOUND' });
});

test('fecha inválida da 400', async () => {
  await assert.rejects(getCalorieStreakService(7, '18-10-2026'), { status: 400, code: 'INVALID_DATE' });
});

test('los días en meta de la semana usan el mismo rango que la racha', async () => {
  repo.getDailyConsumptionRepository = async () => [
    { date: '2026-10-12', totalConsumed: 0 },
    { date: '2026-10-13', totalConsumed: 200 }, // muy poco: no cuenta
    { date: '2026-10-14', totalConsumed: inRange },
    { date: '2026-10-15', totalConsumed: limit },
    { date: '2026-10-16', totalConsumed: limit + 1 }, // se pasó
    { date: '2026-10-17', totalConsumed: inRange },
    { date: '2026-10-18', totalConsumed: 0 },
  ];
  const week = await getWeekStatsService(7, '2026-10-18');
  assert.equal(week.daysOnTarget, 3);
  assert.equal(week.dailyLimit, limit);
});
