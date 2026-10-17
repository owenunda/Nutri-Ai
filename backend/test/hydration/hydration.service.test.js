import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const repo = {};
mock.module(src('modules/hydration/hydration.repository.js'), {
  exports: {
    findWaterHistory: (...args) => repo.findWaterHistory(...args),
    addWaterGlass: (...args) => repo.addWaterGlass(...args),
    undoWaterGlass: (...args) => repo.undoWaterGlass(...args),
    importWaterHistory: (...args) => repo.importWaterHistory(...args),
  },
});

const { getHistoryService, addGlassService, undoGlassService, importHistoryService } = await import(
  src('modules/hydration/hydration.service.js')
);

beforeEach(() => {
  for (const key of Object.keys(repo)) delete repo[key];
});

test('el historial devuelve la meta y los días como objeto', async () => {
  repo.findWaterHistory = async () => [
    { day: '2026-10-16', glasses: 4 },
    { day: '2026-10-17', glasses: 2 },
  ];
  assert.deepEqual(await getHistoryService(7), {
    goal: 4,
    history: { '2026-10-16': 4, '2026-10-17': 2 },
  });
});

test('sumar un vaso devuelve el conteo del día', async () => {
  repo.addWaterGlass = async (userId, date, goal) => {
    assert.deepEqual([userId, date, goal], [7, '2026-10-17', 4]);
    return 3;
  };
  assert.deepEqual(await addGlassService(7, '2026-10-17'), { date: '2026-10-17', glasses: 3 });
});

test('deshacer el último vaso devuelve 0', async () => {
  repo.undoWaterGlass = async () => 0;
  assert.deepEqual(await undoGlassService(7, '2026-10-17'), { date: '2026-10-17', glasses: 0 });
});

test('el import manda los días y cuenta cuántos', async () => {
  let received;
  repo.importWaterHistory = async (userId, entries) => {
    received = { userId, entries };
  };
  const result = await importHistoryService(7, { '2026-10-16': 4, '2026-10-17': 1 });
  assert.deepEqual(result, { imported: 2 });
  assert.deepEqual(received, {
    userId: 7,
    entries: [
      { day: '2026-10-16', glasses: 4 },
      { day: '2026-10-17', glasses: 1 },
    ],
  });
});

test('un import vacío no toca la base', async () => {
  repo.importWaterHistory = async () => assert.fail('no debe llamarse');
  assert.deepEqual(await importHistoryService(7, {}), { imported: 0 });
});
