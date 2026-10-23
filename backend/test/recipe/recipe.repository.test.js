import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const queries = [];
mock.module(src('database/connection.js'), {
  defaultExport: {
    query: async (query) => {
      queries.push(query);
      return { rows: [] };
    },
  },
});

const { getAllRecipesRepository, getRecipeByIdRepository } = await import(src('modules/recipe/recipe.repository.js'));

test('las lecturas de recetas filtran ingredientes por visibilidad y estado', async () => {
  await getAllRecipesRepository(7);
  await getRecipeByIdRepository(7, 12);

  assert.match(queries[0], /f\.is_active = true/);
  assert.match(queries[0], /f\.is_global = true OR f\.created_by_user_id = \$1/);
  assert.match(queries[1], /f\.is_global = true OR f\.created_by_user_id = \$2/);
  assert.match(queries[1], /f2\.is_global = true OR f2\.created_by_user_id = \$2/);
});
