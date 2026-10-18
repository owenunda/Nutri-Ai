import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
let syncImpl;
let webhookImpl;
mock.module(src('modules/subscription/subscription.service.js'), {
  namedExports: {
    syncUser: (...args) => syncImpl(...args),
    handleWebhookEvent: (...args) => webhookImpl(...args),
  },
});

const { receiveWebhook, syncSubscription } = await import(src('modules/subscription/subscription.controller.js'));

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

test('sync: sincroniza al usuario autenticado', async () => {
  let askedFor;
  syncImpl = async (userId) => {
    askedFor = userId;
    return { plan: 'PRO', proUntil: null, proSource: 'store' };
  };
  const res = fakeRes();

  await syncSubscription({ user: { userId: 7 } }, res, () => assert.fail());

  assert.equal(askedFor, 7);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, { plan: 'PRO', proUntil: null, proSource: 'store' });
});

test('sync: un error pasa al errorHandler', async () => {
  const failure = new Error('falla');
  syncImpl = async () => {
    throw failure;
  };
  let received;

  await syncSubscription({ user: { userId: 7 } }, fakeRes(), (error) => {
    received = error;
  });

  assert.equal(received, failure);
});

test('webhook: procesa el evento del body', async () => {
  let event;
  webhookImpl = async (e) => {
    event = e;
    return { synced: [7] };
  };
  const res = fakeRes();

  await receiveWebhook({ body: { event: { type: 'RENEWAL', app_user_id: '7' } } }, res, () => assert.fail());

  assert.deepEqual(event, { type: 'RENEWAL', app_user_id: '7' });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, { synced: [7] });
});
