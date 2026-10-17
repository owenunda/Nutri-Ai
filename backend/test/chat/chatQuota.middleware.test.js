import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let consumeImpl;
mock.module(src('modules/chat/chatQuota.service.js'), {
  namedExports: { consumeChatQuota: (...args) => consumeImpl(...args) },
});

const { chatDailyQuota } = await import(src('middleware/chatQuota.middleware.js'));

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

const freeExhausted = {
  plan: 'FREE', unlimited: false, limit: 3, used: 3, remaining: 0,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: true,
};
const proExhausted = {
  plan: 'PRO', unlimited: true, limit: null, used: null, remaining: null,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: true,
};

test('FREE sin mensajes: 429 CHAT_DAILY_LIMIT en español con la cuota', async () => {
  consumeImpl = async () => ({ allowed: false, quota: freeExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ user: { userId: 1, role: 'USER' } }, res, () => assert.fail('no debe pasar'));

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'CHAT_DAILY_LIMIT');
  assert.equal(res.body.message, 'Usaste tus 3 mensajes de hoy con el Chef IA.');
  assert.deepEqual(res.body.data, { quota: freeExhausted });
});

test('FREE sin mensajes: el mensaje sale en inglés', async () => {
  consumeImpl = async () => ({ allowed: false, quota: freeExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ lang: 'en', user: { userId: 1, role: 'USER' } }, res, () => {});

  assert.equal(res.body.message, "You've used your 3 Chef AI messages for today.");
});

test('PRO en el tope: 429 CHAT_FAIR_USE_LIMIT', async () => {
  consumeImpl = async () => ({ allowed: false, quota: proExhausted, refund: async () => {} });
  const res = fakeRes();
  await chatDailyQuota({ user: { userId: 2, role: 'USER' } }, res, () => {});

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error.code, 'CHAT_FAIR_USE_LIMIT');
  assert.equal(res.body.message, 'Llegaste al límite de uso justo de hoy. Vuelve mañana.');
});

test('con mensajes disponibles deja pasar y guarda la cuota en req', async () => {
  const refund = async () => {};
  const quota = { ...freeExhausted, used: 1, remaining: 2, exhausted: false };
  consumeImpl = async () => ({ allowed: true, quota, refund });
  const req = { user: { userId: 1, role: 'USER' } };
  let nextCalls = 0;
  await chatDailyQuota(req, fakeRes(), (error) => {
    assert.equal(error, undefined);
    nextCalls++;
  });

  assert.equal(nextCalls, 1);
  assert.equal(req.chatQuota.quota, quota);
  assert.equal(req.chatQuota.refund, refund);
});

test('un error del servicio va al manejador de errores', async () => {
  const boom = new Error('db caída');
  consumeImpl = async () => {
    throw boom;
  };
  let received;
  await chatDailyQuota({ user: { userId: 1, role: 'USER' } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, boom);
});
