import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// Redis en memoria: lo justo que usa el servicio.
const store = new Map();
const expirations = new Map();
let redisDown = false;
const fakeRedis = {
  get: async (key) => (store.has(key) ? String(store.get(key)) : null),
  incr: async (key) => {
    const value = (store.get(key) ?? 0) + 1;
    store.set(key, value);
    return value;
  },
  decr: async (key) => {
    const value = (store.get(key) ?? 0) - 1;
    store.set(key, value);
    return value;
  },
  expireAt: async (key, unixSeconds) => {
    expirations.set(key, unixSeconds);
    return true;
  },
};

let plans = {};
mock.module(src('config/redis.client.js'), {
  namedExports: {
    getRedisClient: async () => {
      if (redisDown) throw new Error('ECONNREFUSED');
      return fakeRedis;
    },
  },
});
mock.module(src('modules/chat/chatQuota.repository.js'), {
  namedExports: { findUserPlanById: async (userId) => plans[userId] ?? null },
});

const { AppError } = await import(src('utils/AppError.js'));
const { consumeChatQuota, getChatQuota } = await import(src('modules/chat/chatQuota.service.js'));

const NOW = new Date('2026-10-17T15:00:00Z'); // 10:00 a. m. en Bogotá
const TOMORROW = new Date('2026-10-18T06:00:00Z');
const RESET_AT = '2026-10-18T05:00:00.000Z';
const FREE_USER = { userId: 1, role: 'USER' };
const PRO_USER = { userId: 2, role: 'USER' };
const ADMIN = { userId: 3, role: 'ADMIN' };

beforeEach(() => {
  store.clear();
  expirations.clear();
  redisDown = false;
  plans = { 1: 'FREE', 2: 'PRO' };
});

const consumeTimes = async (user, times, now = NOW) => {
  let last;
  for (let i = 0; i < times; i++) last = await consumeChatQuota(user, now);
  return last;
};

test('FREE: el primer mensaje deja 2 de 3', async () => {
  const { allowed, quota } = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(allowed, true);
  assert.deepEqual(quota, {
    plan: 'FREE',
    unlimited: false,
    limit: 3,
    used: 1,
    remaining: 2,
    resetAt: RESET_AT,
    exhausted: false,
  });
});

test('FREE: el tercero agota y el cuarto se rechaza sin inflar el contador', async () => {
  const third = await consumeTimes(FREE_USER, 3);
  assert.equal(third.allowed, true);
  assert.equal(third.quota.exhausted, true);

  const fourth = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(fourth.allowed, false);
  assert.equal(fourth.quota.remaining, 0);
  assert.equal(fourth.quota.used, 3);
  assert.equal(store.get('quota:chat:1:2026-10-17'), 3);
});

test('la clave expira una hora después de la medianoche de Bogotá', async () => {
  await consumeChatQuota(FREE_USER, NOW);
  assert.equal(
    expirations.get('quota:chat:1:2026-10-17'),
    Date.parse(RESET_AT) / 1000 + 3600
  );
});

test('al día siguiente el contador arranca de nuevo', async () => {
  await consumeTimes(FREE_USER, 3);
  const next = await consumeChatQuota(FREE_USER, TOMORROW);
  assert.equal(next.allowed, true);
  assert.equal(next.quota.used, 1);
});

test('PRO: se ve ilimitado y se corta en el mensaje 51', async () => {
  const fiftieth = await consumeTimes(PRO_USER, 50);
  assert.equal(fiftieth.allowed, true);
  assert.equal(fiftieth.quota.unlimited, true);
  assert.equal(fiftieth.quota.limit, null);
  assert.equal(fiftieth.quota.remaining, null);

  const fiftyFirst = await consumeChatQuota(PRO_USER, NOW);
  assert.equal(fiftyFirst.allowed, false);
  assert.equal(fiftyFirst.quota.unlimited, true);
  assert.equal(fiftyFirst.quota.exhausted, true);
});

test('ADMIN nunca cuenta', async () => {
  const result = await consumeTimes(ADMIN, 100);
  assert.equal(result.allowed, true);
  assert.equal(result.quota.unlimited, true);
  assert.equal(result.quota.exhausted, false);
  assert.equal(store.size, 0);
});

test('refund devuelve el mensaje', async () => {
  const { refund } = await consumeChatQuota(FREE_USER, NOW);
  await refund();
  assert.equal(store.get('quota:chat:1:2026-10-17'), 0);
});

test('con Redis caído deja pasar sin cuota', async () => {
  redisDown = true;
  const result = await consumeChatQuota(FREE_USER, NOW);
  assert.equal(result.allowed, true);
  assert.equal(result.quota, null);
  await result.refund(); // no lanza
});

test('un usuario que no existe es 401', async () => {
  await assert.rejects(
    consumeChatQuota({ userId: 99, role: 'USER' }, NOW),
    (error) => error instanceof AppError && error.status === 401 && error.code === 'UNAUTHORIZED'
  );
});

test('getChatQuota lee sin consumir', async () => {
  await consumeTimes(FREE_USER, 2);
  const first = await getChatQuota(FREE_USER, NOW);
  const second = await getChatQuota(FREE_USER, NOW);
  assert.equal(first.used, 2);
  assert.equal(second.used, 2);
  assert.equal(second.remaining, 1);
});

test('getChatQuota de un usuario nuevo es 0 de 3', async () => {
  const quota = await getChatQuota(FREE_USER, NOW);
  assert.equal(quota.used, 0);
  assert.equal(quota.remaining, 3);
  assert.equal(quota.exhausted, false);
});

test('getChatQuota con Redis caído es null', async () => {
  redisDown = true;
  assert.equal(await getChatQuota(FREE_USER, NOW), null);
});
