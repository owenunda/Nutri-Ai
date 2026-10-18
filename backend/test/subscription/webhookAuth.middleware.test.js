import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const settings = { webhookAuth: 'secreto-largo' };
mock.module(src('config/env_config.js'), { exports: { config: { revenuecat: settings } } });

const { verifyWebhookAuth } = await import(src('modules/subscription/webhookAuth.middleware.js'));

const run = (header) => {
  let received = 'sin llamar';
  const req = { get: (name) => (name.toLowerCase() === 'authorization' ? header : undefined) };
  verifyWebhookAuth(req, {}, (error) => {
    received = error;
  });
  return received;
};

test('el valor correcto pasa', () => {
  settings.webhookAuth = 'secreto-largo';
  assert.equal(run('secreto-largo'), undefined);
});

test('un valor incorrecto responde 401', () => {
  settings.webhookAuth = 'secreto-largo';
  assert.equal(run('otro').status, 401);
  assert.equal(run(undefined).status, 401);
});

test('sin REVENUECAT_WEBHOOK_AUTH configurado rechaza todo', () => {
  settings.webhookAuth = undefined;
  assert.equal(run('').status, 401);
  assert.equal(run('cualquiera').status, 401);
});
