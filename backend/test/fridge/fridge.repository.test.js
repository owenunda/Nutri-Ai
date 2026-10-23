import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
let capturedQuery = '';
let queuedRows = [];
const capturedQueries = [];
mock.module(src('database/connection.js'), {
  defaultExport: {
    query: async (query) => {
      capturedQuery = query;
      capturedQueries.push(query);
      return { rows: queuedRows.shift() ?? [] };
    },
  },
});

const { getOrCreateFridgeByUserIdRepository, updateFridgeItemRepository } = await import(src('modules/fridge/fridge.repository.js'));

test('la actualización de nevera exige alimento activo y visible para el usuario', async () => {
  await updateFridgeItemRepository(15, 7, 4);
  assert.match(capturedQuery, /f\.is_active = true/);
  assert.match(capturedQuery, /f\.is_global = true OR f\.created_by_user_id = \$3/);
});

test('crea la nevera faltante sin duplicarla si hay solicitudes simultáneas', async () => {
  const fridge = { fridgeId: 9, userId: 7, items: [] };
  queuedRows = [[], [], [fridge]];
  capturedQueries.length = 0;

  assert.deepEqual(await getOrCreateFridgeByUserIdRepository(7), fridge);
  assert.match(capturedQueries[1], /INSERT INTO fridges \(user_id\)/);
  assert.match(capturedQueries[1], /ON CONFLICT \(user_id\) DO NOTHING/);
});
