import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

let verifyImpl;
const verifyCalls = [];

mock.module('google-auth-library', {
  exports: {
    OAuth2Client: class {
      verifyIdToken(options) {
        verifyCalls.push(options);
        return verifyImpl(options);
      }
    },
  },
});

const { config } = await import(src('config/env_config.js'));
const { verifyGoogleIdToken } = await import(src('modules/auth/google.verifier.js'));

const ticket = (payload) => ({ getPayload: () => payload });

beforeEach(() => {
  verifyCalls.length = 0;
  config.google.clientIds = ['web-id', 'android-id'];
  verifyImpl = async () =>
    ticket({ sub: '123', email: 'Ana@Gmail.com', email_verified: true, name: 'Ana' });
});

test('devuelve el perfil con el email en minúsculas', async () => {
  const profile = await verifyGoogleIdToken('token');

  assert.deepEqual(profile, {
    sub: '123',
    email: 'ana@gmail.com',
    emailVerified: true,
    name: 'Ana',
  });
  assert.deepEqual(verifyCalls[0], { idToken: 'token', audience: ['web-id', 'android-id'] });
});

test('email_verified distinto de true cuenta como no verificado', async () => {
  verifyImpl = async () => ticket({ sub: '123', email: 'ana@gmail.com', email_verified: 'true' });

  const profile = await verifyGoogleIdToken('token');

  assert.equal(profile.emailVerified, false);
  assert.equal(profile.name, null);
});

test('token rechazado por Google: 401 INVALID_GOOGLE_TOKEN', async () => {
  verifyImpl = async () => {
    throw new Error('Token used too late');
  };
  const warn = mock.method(console, 'warn', () => {});

  try {
    await assert.rejects(verifyGoogleIdToken('token'), {
      status: 401,
      code: 'INVALID_GOOGLE_TOKEN',
    });
    assert.equal(warn.mock.callCount(), 1);
  } finally {
    warn.mock.restore();
  }
});

test('payload sin sub o sin email: 401 INVALID_GOOGLE_TOKEN', async () => {
  verifyImpl = async () => ticket({ sub: '123' });

  await assert.rejects(verifyGoogleIdToken('token'), {
    status: 401,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('sin client IDs configurados: 500 AUTH_CONFIG_ERROR', async () => {
  config.google.clientIds = [];

  await assert.rejects(verifyGoogleIdToken('token'), {
    status: 500,
    code: 'AUTH_CONFIG_ERROR',
  });
  assert.equal(verifyCalls.length, 0);
});
