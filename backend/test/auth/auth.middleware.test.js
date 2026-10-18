import { test } from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { config } = await import(src('config/env_config.js'));
const { default: authenticateToken, rejectGuests } = await import(src('middleware/auth.middleware.js'));

config.jwt.secret = 'test-secret';

const run = (middleware, req) =>
  new Promise((resolve) => middleware(req, {}, (error) => resolve({ error, req })));

const bearer = (payload) => ({
  headers: { authorization: `Bearer ${jwt.sign(payload, 'test-secret')}` },
});

const expired = Math.floor(Date.now() / 1000) - 60;

test('un invitado vencido recibe GUEST_EXPIRED', async () => {
  const { error } = await run(authenticateToken(), bearer({ userId: 1, isGuest: true, exp: expired }));
  assert.equal(error.status, 401);
  assert.equal(error.code, 'GUEST_EXPIRED');
});

test('un usuario normal vencido sigue recibiendo UNAUTHORIZED', async () => {
  const { error } = await run(authenticateToken(), bearer({ userId: 1, exp: expired }));
  assert.equal(error.status, 401);
  assert.equal(error.code, 'UNAUTHORIZED');
});

test('un invitado vigente pasa y queda marcado', async () => {
  const { error, req } = await run(authenticateToken(), bearer({ userId: 1, role: 'USER', isGuest: true }));
  assert.equal(error, undefined);
  assert.equal(req.user.isGuest, true);
});

test('rejectGuests frena al invitado', async () => {
  const { error } = await run(rejectGuests, { user: { userId: 1, isGuest: true } });
  assert.equal(error.status, 403);
  assert.equal(error.code, 'GUEST_NOT_ALLOWED');
});

test('rejectGuests deja pasar a los demás', async () => {
  const { error } = await run(rejectGuests, { user: { userId: 1 } });
  assert.equal(error, undefined);
});
