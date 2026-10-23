import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const writes = [];
let visibleIds = [];

mock.module(src('modules/food/food.repository.js'), {
  namedExports: {
    checkFoodsVisible: async (userId, ids) => {
      assert.equal(userId, 7);
      assert.deepEqual(ids, [41]);
      return visibleIds;
    },
  },
});
mock.module(src('modules/recipe/recipe.repository.js'), {
  namedExports: {
    getAllRecipesRepository: async () => [],
    createRecipeRepository: async () => ({}),
    addIngredientsToRecipeRepository: async (...args) => {
      writes.push(args);
      return { recipe_id: args[1] };
    },
    getRecipeByIdRepository: async () => null,
    updateRecipeStatusRepository: async () => null,
    updateRecipeActionRepository: async () => null,
  },
});

const { addIngredientsToRecipeService } = await import(src('modules/recipe/recipe.service.js'));
const ingredients = [{ food_id: 41, quantity: 2, unit: 'g' }];

test('no guarda en una receta un alimento privado de otro usuario', async () => {
  visibleIds = [];
  writes.length = 0;

  await assert.rejects(addIngredientsToRecipeService(7, 12, ingredients), {
    status: 404,
    code: 'FOOD_NOT_FOUND',
  });
  assert.equal(writes.length, 0);
});

test('permite agregar alimentos visibles al usuario', async () => {
  visibleIds = [41];
  writes.length = 0;

  await addIngredientsToRecipeService(7, 12, ingredients);
  assert.equal(writes.length, 1);
});
