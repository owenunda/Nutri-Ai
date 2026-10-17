import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const calls = [];
mock.module(src('modules/hydration/hydration.service.js'), {
  exports: {
    DAILY_GOAL: 4,
    getHistoryService: async (userId) => (calls.push(['get', userId]), { goal: 4, history: {} }),
    addGlassService: async (userId, date) => (calls.push(['add', userId, date]), { date, glasses: 1 }),
    undoGlassService: async (userId, date) => (calls.push(['undo', userId, date]), { date, glasses: 0 }),
    importHistoryService: async (userId, history) => (calls.push(['import', userId, history]), { imported: 1 }),
  },
});

const controller = await import(src('modules/hydration/hydration.controller.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => ((res.statusCode = code), res);
  res.json = (body) => ((res.body = body), res);
  return res;
};

test('cada handler llama a su servicio con el usuario del token', async () => {
  const user = { userId: 7 };
  const cases = [
    [controller.getHistory, { user }, { goal: 4, history: {} }],
    [controller.addGlass, { user, hydrationDate: '2026-10-17' }, { date: '2026-10-17', glasses: 1 }],
    [controller.undoGlass, { user, hydrationDate: '2026-10-17' }, { date: '2026-10-17', glasses: 0 }],
    [controller.importHistory, { user, hydrationHistory: { '2026-10-16': 4 } }, { imported: 1 }],
  ];
  for (const [handler, req, data] of cases) {
    const res = fakeRes();
    await handler(req, res, (error) => assert.fail(error));
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.body.data, data);
  }
  assert.deepEqual(calls, [
    ['get', 7],
    ['add', 7, '2026-10-17'],
    ['undo', 7, '2026-10-17'],
    ['import', 7, { '2026-10-16': 4 }],
  ]);
});
