import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let getImpl;
mock.module(src('modules/chat/chatQuota.service.js'), {
  namedExports: { getChatQuota: (...args) => getImpl(...args) },
});

const { getChatQuotaController } = await import(src('modules/chat/chatQuota.controller.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
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

test('devuelve la cuota del usuario autenticado', async () => {
  const quota = { plan: 'FREE', unlimited: false, limit: 3, used: 0, remaining: 3, resetAt: 'x', exhausted: false };
  let askedFor;
  getImpl = async (user) => {
    askedFor = user;
    return quota;
  };
  const res = fakeRes();
  await getChatQuotaController({ user: { userId: 1, role: 'USER' } }, res, () => assert.fail());

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, quota);
  assert.deepEqual(askedFor, { userId: 1, role: 'USER' });
});

test('los errores van a next', async () => {
  const boom = new Error('boom');
  getImpl = async () => {
    throw boom;
  };
  let received;
  await getChatQuotaController({ user: { userId: 1 } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, boom);
});
