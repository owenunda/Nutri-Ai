import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

process.env.REDIS_URL = 'redis://127.0.0.1:6399';

// Cada test fija cómo se comporta el connect() del cliente falso.
let connectImpl;
let created = [];
const fakeClient = () => {
  const c = {
    isOpen: false,
    opts: null,
    handlers: {},
    on(event, fn) {
      c.handlers[event] = fn;
      return c;
    },
    connect: () => connectImpl(c),
    disconnect: async () => {},
  };
  return c;
};
mock.module('redis', {
  namedExports: {
    createClient: (opts) => {
      const c = fakeClient();
      c.opts = opts;
      created.push(c);
      return c;
    },
  },
});

mock.module(src('modules/chat/chatQuota.repository.js'), {
  namedExports: { findUserPlanById: async () => 'FREE' },
});

const { getRedisClient } = await import(src('config/redis.client.js'));
const { chatRateLimit } = await import(src('middleware/rateLimit.middleware.js'));
const { consumeChatQuota } = await import(src('modules/chat/chatQuota.service.js'));

test('connect que nunca resuelve: el rate limit deja pasar en tiempo acotado', async (t) => {
  created = [];
  connectImpl = () => new Promise(() => {});
  t.mock.timers.enable({ apis: ['setTimeout'] });

  let passed = false;
  const run = chatRateLimit({ user: { userId: 1 }, ip: '1.1.1.1' }, {}, () => {
    passed = true;
  });
  t.mock.timers.tick(5000);
  await run;

  assert.equal(passed, true);
});

test('connect que rechaza: el rate limit deja pasar y el siguiente llamado reintenta', async () => {
  created = [];
  connectImpl = async () => {
    throw new Error('ECONNREFUSED');
  };

  for (let i = 0; i < 2; i++) {
    let passed = false;
    await chatRateLimit({ user: { userId: 1 }, ip: '1.1.1.1' }, {}, () => {
      passed = true;
    });
    assert.equal(passed, true);
  }
  assert.equal(created.length, 2, 'cada llamado crea un cliente nuevo');
});

test('con Redis caído la cuota diaria deja pasar en tiempo acotado', async () => {
  connectImpl = async () => {
    throw new Error('ECONNREFUSED');
  };
  const result = await consumeChatQuota({ role: 'USER', userId: 1 });
  assert.equal(result.allowed, true);
  assert.equal(result.quota, null);
});

test('connect que nunca resuelve: getRedisClient rechaza y libera el intento', async (t) => {
  created = [];
  connectImpl = () => new Promise(() => {});
  t.mock.timers.enable({ apis: ['setTimeout'] });

  const first = assert.rejects(getRedisClient(), /timeout/);
  t.mock.timers.tick(5000);
  await first;

  const second = assert.rejects(getRedisClient(), /timeout/);
  t.mock.timers.tick(5000);
  await second;
  assert.equal(created.length, 2);
});

test('la reconnectStrategy se rinde en la primera conexión y reconecta si ya estuvo listo', async () => {
  created = [];
  connectImpl = async () => {
    throw new Error('x');
  };
  await assert.rejects(getRedisClient());
  const c = created[0];
  const { socket, disableOfflineQueue } = c.opts;

  assert.equal(disableOfflineQueue, true);
  assert.ok(socket.connectTimeout > 0 && socket.connectTimeout <= 5000);
  assert.equal(typeof socket.reconnectStrategy(0), 'number');
  assert.ok(socket.reconnectStrategy(10) instanceof Error);

  c.handlers.ready();
  assert.equal(typeof socket.reconnectStrategy(10), 'number');
});
