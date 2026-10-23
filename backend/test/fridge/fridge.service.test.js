import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
let visibleIds = [];
let upserts = 0;
let updatedItem = null;
let fridgeEnsures = 0;

mock.module(src('modules/food/food.repository.js'), {
  namedExports: { checkFoodsVisible: async () => visibleIds },
});
mock.module(src('modules/fridge/fridge.repository.js'), {
  namedExports: {
    addFridgeItemRepository: async () => ({}),
    findFridgeItemsByIdsRepository: async () => [],
    findAttachableFoodsByIdsRepository: async () => [],
    addOrUpdateFridgeItemRepository: async (...args) => {
      upserts += 1;
      return { foodId: args[1] };
    },
    createFridgeRepository: async () => ({}),
    getFridgeByUserIdRepository: async () => ({ fridgeId: 3 }),
    getOrCreateFridgeByUserIdRepository: async (userId) => {
      fridgeEnsures++;
      return { fridgeId: 3, userId, items: [] };
    },
    updateFridgeItemRepository: async () => updatedItem,
    deleteFridgeItemRepository: async () => null,
  },
});

const { addItemToFridgeWithQuantityService, getFridge, updateFridgeItemService } = await import(src('modules/fridge/fridge.service.js'));

test('consulta la nevera a través del helper que la crea si no existe', async () => {
  fridgeEnsures = 0;
  const fridge = await getFridge(7);
  assert.equal(fridge.fridgeId, 3);
  assert.equal(fridge.userId, 7);
  assert.equal(fridgeEnsures, 1);
});

test('no agrega a la nevera un alimento privado de otro usuario', async () => {
  visibleIds = [];
  upserts = 0;

  await assert.rejects(addItemToFridgeWithQuantityService(7, 41, 2, 'g'), {
    status: 404,
    code: 'FOOD_NOT_FOUND',
  });
  assert.equal(upserts, 0);
});

test('permite agregar alimento visible y limita actualización a items visibles', async () => {
  visibleIds = [41];
  upserts = 0;
  await addItemToFridgeWithQuantityService(7, 41, 2, 'g');
  assert.equal(upserts, 1);

  updatedItem = null;
  await assert.rejects(updateFridgeItemService(7, 15, 4), {
    status: 404,
    code: 'FRIDGE_ITEM_NOT_FOUND',
  });
});
