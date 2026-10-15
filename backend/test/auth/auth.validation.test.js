import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  validateGoogleLinkRequest,
  validateGoogleLoginRequest,
} from '../../src/modules/auth/auth.validation.js';

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

const runLink = (body) => {
  const req = { body };
  let nextArg = 'not-called';
  validateGoogleLinkRequest(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('vincular: idToken y contraseña pasan como req.googleLinkData', () => {
  const { req, nextArg } = runLink({ idToken: ' abc ', password: 'secreto123' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.googleLinkData, { idToken: 'abc', password: 'secreto123' });
});

for (const body of [{}, { idToken: 'abc' }, { password: 'x' }, { idToken: ' ', password: 'x' }, { idToken: 'abc', password: '' }, undefined]) {
  test(`vincular: body inválido ${JSON.stringify(body)} responde 400`, () => {
    const { nextArg } = runLink(body);

    assert.equal(nextArg.status, 400);
    assert.equal(nextArg.code, 'VALIDATION_ERROR');
  });
}
