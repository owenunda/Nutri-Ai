import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// El controlador solo debe pasar req.lang al servicio; el servicio es falso.
const calls = {};
const record = (name) => async (input) => {
  calls[name] = input;
  return {};
};

mock.module(src('modules/auth/auth.service.js'), {
  namedExports: {
    forgotPassword: record('forgotPassword'),
    getAuthModuleStatus: record('getAuthModuleStatus'),
    linkGoogleAccount: record('linkGoogleAccount'),
    loginUser: record('loginUser'),
    loginWithGoogle: record('loginWithGoogle'),
    registerUser: record('registerUser'),
    resendVerification: record('resendVerification'),
    resetPassword: record('resetPassword'),
    verifyEmail: record('verifyEmail'),
  },
});

const {
  login,
  register,
  resendVerificationController,
  forgotPasswordController,
} = await import(src('modules/auth/auth.controller.js'));

const fakeRes = () => {
  const res = {};
  res.status = () => res;
  res.json = () => res;
  return res;
};

const fail = (error) => assert.fail(error?.message ?? 'next(error)');

beforeEach(() => {
  for (const key of Object.keys(calls)) delete calls[key];
});

test('login pasa el idioma de la petición al servicio', async () => {
  await login({ lang: 'en', loginData: { email: 'a@b.co', password: 'x' } }, fakeRes(), fail);
  assert.deepEqual(calls.loginUser, { email: 'a@b.co', password: 'x', lang: 'en' });
});

test('registro pasa el idioma de la petición al servicio', async () => {
  await register({ lang: 'en', registerData: { name: 'Ana', email: 'a@b.co' } }, fakeRes(), fail);
  assert.equal(calls.registerUser.lang, 'en');
  assert.equal(calls.registerUser.name, 'Ana');
});

test('reenviar y olvidé mi contraseña pasan el idioma al servicio', async () => {
  await resendVerificationController({ lang: 'en', emailData: { email: 'a@b.co' } }, fakeRes(), fail);
  await forgotPasswordController({ lang: 'es', emailData: { email: 'a@b.co' } }, fakeRes(), fail);
  assert.deepEqual(calls.resendVerification, { email: 'a@b.co', lang: 'en' });
  assert.deepEqual(calls.forgotPassword, { email: 'a@b.co', lang: 'es' });
});
