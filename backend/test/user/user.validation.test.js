import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateDeleteAccountRequest } from '../../src/modules/user/user.validation.js';

const run = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateDeleteAccountRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('acepta solo contraseña', () => {
  const { req, nextArg } = run({ password: 'secreto123' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.accountDeletionData, { password: 'secreto123' });
});

test('acepta solo googleIdToken', () => {
  const { req, nextArg } = run({ googleIdToken: 'tok' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.accountDeletionData, { googleIdToken: 'tok' });
});

for (const body of [{}, { password: '' }, { password: 'a', googleIdToken: 'b' }, undefined]) {
  test(`rechaza ${JSON.stringify(body)} con 400`, () => {
    const { nextArg } = run(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.code, 'VALIDATION_ERROR');
  });
}
