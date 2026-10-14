import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateGoogleLoginRequest } from '../../src/modules/auth/auth.validation.js';

const run = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateGoogleLoginRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('idToken válido pasa como req.googleLoginData', () => {
  const { req, nextArg } = run({ idToken: '  abc  ' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.googleLoginData, { idToken: 'abc' });
});

for (const body of [{}, { idToken: '' }, { idToken: '   ' }, { idToken: 42 }, undefined]) {
  test(`body inválido ${JSON.stringify(body)} responde 400`, () => {
    const { nextArg } = run(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.code, 'VALIDATION_ERROR');
    assert.equal(nextArg.details[0].field, 'idToken');
  });
}
