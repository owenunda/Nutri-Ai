import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const settings = { secretKey: 'sk_test_123' };
let getImpl;
const getCalls = [];

mock.module('axios', {
  exports: {
    default: {
      get: (...args) => {
        getCalls.push(args);
        return getImpl(...args);
      },
    },
  },
});
mock.module(src('config/env_config.js'), {
  exports: { config: { revenuecat: settings } },
});

const { fetchSubscriber } = await import(src('modules/subscription/revenuecat.client.js'));

beforeEach(() => {
  settings.secretKey = 'sk_test_123';
  getCalls.length = 0;
  getImpl = async () => ({ data: { subscriber: { entitlements: {} } } });
});

const silence = async (fn) => {
  const original = console.error;
  console.error = () => {};
  try {
    return await fn();
  } finally {
    console.error = original;
  }
};

test('sin clave secreta responde 502 sin llamar a RevenueCat', async () => {
  settings.secretKey = '';

  await silence(() =>
    assert.rejects(fetchSubscriber('7'), { status: 502, code: 'SUBSCRIPTION_PROVIDER_ERROR' })
  );
  assert.equal(getCalls.length, 0);
});

test('si la llamada falla responde 502', async () => {
  getImpl = async () => {
    throw new Error('timeout');
  };

  await silence(() =>
    assert.rejects(fetchSubscriber('7'), { status: 502, code: 'SUBSCRIPTION_PROVIDER_ERROR' })
  );
});

test('una respuesta sin subscriber no se lee como "sin suscripción"', async () => {
  getImpl = async () => ({ data: { unexpected: true } });

  await silence(() =>
    assert.rejects(fetchSubscriber('7'), { status: 502, code: 'SUBSCRIPTION_PROVIDER_ERROR' })
  );
});

test('con subscriber devuelve el suscriptor y llama a la URL con la clave', async () => {
  const subscriber = { entitlements: { nutrilife_pro: {} } };
  getImpl = async () => ({ data: { subscriber } });

  assert.deepEqual(await fetchSubscriber('7'), subscriber);
  assert.equal(getCalls.length, 1);
  const [url, options] = getCalls[0];
  assert.equal(url, 'https://api.revenuecat.com/v1/subscribers/7');
  assert.equal(options.headers.Authorization, 'Bearer sk_test_123');
  assert.equal(options.timeout, 10000);
});
