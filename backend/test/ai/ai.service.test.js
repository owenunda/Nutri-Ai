import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const dbCalls = [];
const client = {
  query: async (query) => {
    dbCalls.push(query);
    return { rows: query.includes('RETURNING recipe_id') ? [{ recipe_id: 21 }] : [] };
  },
  release: () => {},
};
let visibleIds = [];
let visibilityClient;

mock.module(src('database/connection.js'), {
  defaultExport: { connect: async () => client },
});
mock.module(src('modules/food/food.repository.js'), {
  namedExports: {
    checkFoodsVisible: async (userId, ids, db) => {
      assert.equal(userId, 7);
      assert.deepEqual(ids, [41]);
      visibilityClient = db;
      return visibleIds;
    },
  },
});
mock.module(src('modules/recipe/recipe.repository.js'), {
  namedExports: { getRecipeByIdRepository: async () => ({ recipe_id: 21 }) },
});

const { saveGeneratedRecipeService } = await import(src('modules/ai/ai.service.js'));
const recipe = { name: 'Receta', ingredients: [{ food_id: 41, quantity: 2, unit: 'g' }] };

test('revierte la receta generada si incluye alimento no visible', async () => {
  visibleIds = [];
  visibilityClient = null;
  dbCalls.length = 0;

  await assert.rejects(saveGeneratedRecipeService(7, recipe), {
    status: 404,
    code: 'FOOD_NOT_FOUND',
  });
  assert.equal(visibilityClient, client);
  assert.deepEqual(dbCalls, ['BEGIN', 'ROLLBACK']);
});

test('guarda receta generada cuando sus alimentos son visibles', async () => {
  visibleIds = [41];
  dbCalls.length = 0;

  const saved = await saveGeneratedRecipeService(7, recipe);
  assert.equal(saved.recipe_id, 21);
  assert.equal(dbCalls[0], 'BEGIN');
  assert.equal(dbCalls.at(-1), 'COMMIT');
});
