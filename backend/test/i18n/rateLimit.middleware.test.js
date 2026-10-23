import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// Redis falso y un limitador que siempre rechaza: la petición superó el límite.
mock.module(src('config/redis.client.js'), {
  namedExports: { getRedisClient: async () => ({}) },
});
mock.module('rate-limiter-flexible', {
  namedExports: {
    RateLimiterRedis: class {
      async consume() {
        throw { msBeforeNext: 2500 };
      }
    },
  },
});

const { chatRateLimit, strictAuthRateLimit } = await import(src('middleware/rateLimit.middleware.js'));

const fakeRes = () => {
  const res = { headers: {}, statusCode: null, body: null };
  res.setHeader = (name, value) => {
    res.headers[name] = value;
  };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

test('el 429 del límite de mensajes sale en inglés', async () => {
  const res = fakeRes();
  await chatRateLimit({ lang: 'en', user: { userId: 7 }, ip: '1.1.1.1' }, res, () => {
    assert.fail('no debe dejar pasar la petición');
  });

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'RATE_LIMIT_EXCEEDED');
  assert.equal(res.body.message, 'Too many requests. Try again in a few seconds.');
  assert.equal(res.headers['Retry-After'], '3');
});

test('el 429 sin idioma sigue en español', async () => {
  const res = fakeRes();
  await chatRateLimit({ user: { userId: 7 }, ip: '1.1.1.1' }, res, () => {});

  assert.equal(
    res.body.message,
    'Has superado el límite de solicitudes. Intenta de nuevo en unos segundos.'
  );
});

test('el límite estricto de autenticación bloquea al superar el máximo', async () => {
  const res = fakeRes();
  await strictAuthRateLimit({ lang: 'en', ip: '1.1.1.1' }, res, () => {
    assert.fail('no debe dejar pasar la petición');
  });

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'RATE_LIMIT_EXCEEDED');
});
