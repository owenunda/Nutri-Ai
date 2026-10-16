import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  validateEmailOnlyRequest,
  validateGoogleLinkRequest,
  validateGoogleLoginRequest,
  validateResetPasswordRequest,
  validateVerifyEmailRequest,
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

const runWith = (validator, body) => {
  const req = { body };
  let nextArg = 'not-called';
  validator(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, nextArg };
};

test('verificar: correo y código de 6 dígitos pasan normalizados', () => {
  const { req, nextArg } = runWith(validateVerifyEmailRequest, {
    email: ' Ana@Gmail.com ',
    code: ' 482913 ',
  });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.verifyEmailData, { email: 'ana@gmail.com', code: '482913' });
});

for (const body of [{}, { email: 'ana@gmail.com' }, { email: 'ana@gmail.com', code: '12345' }, { email: 'ana@gmail.com', code: 'abcdef' }, { email: 'no-es-correo', code: '482913' }]) {
  test(`verificar: rechaza ${JSON.stringify(body)} con 400`, () => {
    assert.equal(runWith(validateVerifyEmailRequest, body).nextArg.status, 400);
  });
}

test('solo correo: pasa normalizado', () => {
  const { req, nextArg } = runWith(validateEmailOnlyRequest, { email: ' Ana@Gmail.com ' });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.emailData, { email: 'ana@gmail.com' });
});

for (const body of [{}, { email: '' }, { email: 'no-es-correo' }, undefined]) {
  test(`solo correo: rechaza ${JSON.stringify(body)} con 400`, () => {
    assert.equal(runWith(validateEmailOnlyRequest, body).nextArg.status, 400);
  });
}

test('restablecer: correo, código y contraseña pasan', () => {
  const { req, nextArg } = runWith(validateResetPasswordRequest, {
    email: 'ana@gmail.com',
    code: '482913',
    password: 'nueva123',
  });

  assert.equal(nextArg, undefined);
  assert.deepEqual(req.resetPasswordData, {
    email: 'ana@gmail.com',
    code: '482913',
    password: 'nueva123',
  });
});

for (const body of [
  { email: 'ana@gmail.com', code: '482913' },
  { email: 'ana@gmail.com', code: '482913', password: '12345' },
  { email: 'ana@gmail.com', code: '4829', password: 'nueva123' },
]) {
  test(`restablecer: rechaza ${JSON.stringify(body)} con 400`, () => {
    assert.equal(runWith(validateResetPasswordRequest, body).nextArg.status, 400);
  });
}
