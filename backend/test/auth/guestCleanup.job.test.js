import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
let retentionImpl;
const retentionCalls = [];

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
mock.module(src('modules/events/events.service.js'), {
  exports: {
    runRetentionService: (...args) => retentionImpl(...args),
  },
});

const { runDailyRetention, runGuestCleanup, runGuestCleanupJob } = await import(src('modules/auth/guestCleanup.job.js'));

beforeEach(() => {
  retentionCalls.length = 0;
  retentionImpl = async (...args) => {
    retentionCalls.push(args[0]);
    return { deleted: 0, ...args[0] };
  };
});

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

test('el job ejecuta la retención de 90 días una sola vez por día', async () => {
  await quiet(() => runGuestCleanupJob(new Date('2026-10-22T08:00:00.000Z')));
  await quiet(() => runGuestCleanupJob(new Date('2026-10-22T16:00:00.000Z')));
  assert.deepEqual(retentionCalls, [{ days: 90 }]);

  await quiet(() => runGuestCleanupJob(new Date('2026-10-23T01:00:00.000Z')));
  assert.deepEqual(retentionCalls, [{ days: 90 }, { days: 90 }]);
});

test('si falla la retención, el job puede reintentar en el próximo ciclo horario', async () => {
  let attempts = 0;
  retentionImpl = async (options) => {
    retentionCalls.push(options);
    attempts++;
    if (attempts === 1) throw new Error('db caída');
    return { deleted: 0, ...options };
  };

  const firstAttempt = await quiet(() => runDailyRetention(new Date('2026-10-24T08:00:00.000Z')));
  const retry = await quiet(() => runDailyRetention(new Date('2026-10-24T09:00:00.000Z')));
  assert.equal(firstAttempt, null);
  assert.deepEqual(retry, { deleted: 0, days: 90 });
  assert.equal(attempts, 2);
});
