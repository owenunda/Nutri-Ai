import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const created = [];
mock.module(src('config/redis.client.js'), {
  namedExports: { getRedisClient: async () => ({}) },
});
mock.module('rate-limiter-flexible', {
  namedExports: {
    RateLimiterRedis: class {
      constructor(opts) {
        created.push(opts);
      }
      async consume() {
        return { remainingPoints: 4, msBeforeNext: 1000 };
      }
    },
  },
});

const { guestRateLimit, chatRateLimit } = await import(src('middleware/rateLimit.middleware.js'));

const res = { setHeader() {} };

test('el invitado se limita a 5 por hora por IP', async () => {
  await guestRateLimit({ ip: '1.1.1.1' }, res, () => {});
  const opts = created.at(-1);
  assert.equal(opts.points, 5);
  assert.equal(opts.duration, 3600);
  assert.equal(opts.keyPrefix, 'rl:auth-guest');
});

test('los demás límites siguen siendo por minuto', async () => {
  await chatRateLimit({ ip: '1.1.1.1', user: { userId: 1 } }, res, () => {});
  assert.equal(created.at(-1).duration, 60);
});
