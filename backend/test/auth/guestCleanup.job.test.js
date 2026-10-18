import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// El job importa los repositorios (y con ellos la base): se reemplazan.
mock.module(src('modules/auth/guest.repository.js'), {
  exports: {
    findExpiredGuestIds: async () => [],
    findSampleFoodIds: async () => [],
    createGuestAccount: async () => 0,
    countActiveGuests: async () => 0,
  },
});
mock.module(src('modules/user/user.repository.js'), {
  exports: { deleteUserAccountData: async () => true },
});

const { runGuestCleanup } = await import(src('modules/auth/guestCleanup.job.js'));

const quiet = async (fn) => {
  const { error, info } = console;
  console.error = () => {};
  console.info = () => {};
  try {
    return await fn();
  } finally {
    console.error = error;
    console.info = info;
  }
};

test('borra a cada invitado vencido', async () => {
  const deleted = [];
  const result = await quiet(() =>
    runGuestCleanup(async () => [3, 8], async (id) => {
      deleted.push(id);
      return true;
    })
  );
  assert.deepEqual(deleted, [3, 8]);
  assert.deepEqual(result, [3, 8]);
});

test('si uno falla, sigue con los demás', async () => {
  const result = await quiet(() =>
    runGuestCleanup(async () => [3, 8], async (id) => {
      if (id === 3) throw new Error('db caída');
      return true;
    })
  );
  assert.deepEqual(result, [8]);
});

test('no cuenta a quien ya no existía', async () => {
  const result = await quiet(() => runGuestCleanup(async () => [3], async () => false));
  assert.deepEqual(result, []);
});

test('un fallo al buscar no lanza', async () => {
  const result = await quiet(() =>
    runGuestCleanup(async () => {
      throw new Error('db caída');
    }, async () => true)
  );
  assert.deepEqual(result, []);
});

test('un fallo que no es un Error tampoco lanza', async () => {
  const result = await quiet(() =>
    runGuestCleanup(async () => {
      throw null;
    }, async () => true)
  );
  assert.deepEqual(result, []);
});
