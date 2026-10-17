import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let sendImpl;
mock.module(src('utils/n8n.service.js'), {
  namedExports: { sendChatN8n: (...args) => sendImpl(...args) },
});
mock.module(src('modules/fridge/fridge.service.js'), {
  namedExports: { getFridgeItemsByIdsService: async () => [] },
});

const { AppError } = await import(src('utils/AppError.js'));
const { sendChatMessageController } = await import(src('modules/chat/chatMessage.controller.js'));

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

const quota = {
  plan: 'FREE', unlimited: false, limit: 3, used: 1, remaining: 2,
  resetAt: '2026-10-18T05:00:00.000Z', exhausted: false,
};
let refunds;
const buildReq = (overrides = {}) => ({
  body: { message: 'quiero un desayuno' },
  user: { userId: 1, name: 'Ana' },
  headers: { authorization: 'Bearer jwt' },
  chatQuota: {
    quota,
    refund: async () => {
      refunds++;
    },
  },
  ...overrides,
});

beforeEach(() => {
  refunds = 0;
  sendImpl = async () => ({ type: 'CHAT', message: 'hola', recipe: null });
});

test('la respuesta del chat trae la cuota', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq(), res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.type, 'CHAT');
  assert.deepEqual(res.body.data.quota, quota);
  assert.equal(refunds, 0);
});

test('con Redis caído la cuota va en null', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ chatQuota: { quota: null, refund: async () => {} } }), res);

  assert.equal(res.body.data.quota, null);
});

test('si n8n falla devuelve el mensaje y responde 503 amigable', async () => {
  sendImpl = async () => {
    throw new AppError('El Chef está descansando un momento. Intenta de nuevo en un rato.', 503, 'N8N_ERROR');
  };
  const res = fakeRes();
  await sendChatMessageController(buildReq(), res);

  assert.equal(refunds, 1);
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.error.code, 'N8N_ERROR');
  assert.equal(res.body.message, 'El Chef está descansando un momento. Intenta de nuevo en un rato.');
});

test('el error amigable sale en inglés', async () => {
  sendImpl = async () => {
    throw new AppError('El Chef está descansando un momento. Intenta de nuevo en un rato.', 503, 'N8N_ERROR');
  };
  const res = fakeRes();
  await sendChatMessageController(buildReq({ lang: 'en' }), res);

  assert.equal(res.body.message, 'The Chef is taking a short break. Try again in a little while.');
});

test('un mensaje vacío no cuenta', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ body: { message: '' } }), res);

  assert.equal(res.statusCode, 400);
  assert.equal(refunds, 1);
});

test('sin req.chatQuota no revienta', async () => {
  const res = fakeRes();
  await sendChatMessageController(buildReq({ chatQuota: undefined }), res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.quota, null);
});
