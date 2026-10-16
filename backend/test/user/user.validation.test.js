import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  validateDeleteAccountRequest,
  validateSetPasswordRequest,
} from '../../src/modules/user/user.validation.js';

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

const runSetPassword = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateSetPasswordRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('crear contraseña: acepta 6 caracteres o más', () => {
  const { req, nextArg } = runSetPassword({ password: 'abc123' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.setPasswordData, { password: 'abc123' });
});

for (const body of [{}, { password: '' }, { password: 'abc12' }, { password: 123456 }, undefined]) {
  test(`crear contraseña: rechaza ${JSON.stringify(body)} con 400`, () => {
    const { nextArg } = runSetPassword(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.details[0].field, 'password');
  });
}
