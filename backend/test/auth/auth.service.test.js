import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = [
  'createUser',
  'createUserWithProvider',
  'findProviderLink',
  'findUserByEmail',
  'findUserByProvider',
  'getAuthRepositoryStatus',
  'getDefaultRoleAndPlanIds',
  'linkProviderToExistingUser',
];

const repo = {};
const events = [];
let googleProfile;

mock.module(src('modules/auth/auth.repository.js'), {
  exports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/fridge/fridge.service.js'), {
  exports: { createFridgeService: async () => {} },
});
mock.module(src('modules/events/events.service.js'), {
  exports: {
    logEventService: async (event) => {
      events.push(event);
    },
  },
});
mock.module(src('modules/auth/google.verifier.js'), {
  exports: { verifyGoogleIdToken: async () => googleProfile },
});

const { config } = await import(src('config/env_config.js'));
const { loginUser, loginWithGoogle } = await import(src('modules/auth/auth.service.js'));

const ana = {
  userId: 7,
  name: 'Ana',
  email: 'ana@gmail.com',
  passwordHash: 'hash',
  goal: null,
  age: 30,
  role: 'USER',
  plan: 'FREE',
};

const fail = (name) => async () => {
  throw new Error(`${name} no debería llamarse`);
};

beforeEach(() => {
  config.jwt.secret = 'test_secret';
  events.length = 0;
  googleProfile = { sub: 'sub-1', email: 'ana@gmail.com', emailVerified: true, name: 'Ana' };
  Object.assign(repo, {
    createUser: fail('createUser'),
    createUserWithProvider: fail('createUserWithProvider'),
    findProviderLink: async () => null,
    findUserByEmail: async () => null,
    findUserByProvider: async () => null,
    getAuthRepositoryStatus: async () => ({}),
    getDefaultRoleAndPlanIds: async () => ({ roleId: 2, planId: 1 }),
    linkProviderToExistingUser: fail('linkProviderToExistingUser'),
  });
});

const eventTypes = () => events.map((event) => event.eventType);

test('Google: usuario ya vinculado entra sin crear ni vincular nada', async () => {
  repo.findUserByProvider = async (provider, sub) => {
    assert.equal(provider, 'google');
    assert.equal(sub, 'sub-1');
    return ana;
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.equal(jwt.verify(session.token, 'test_secret').userId, 7);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.user.email, 'ana@gmail.com');
  assert.equal(session.needsProfileSetup, false);
  assert.deepEqual(eventTypes(), ['LOGIN']);
  assert.equal(events[0].metadata.method, 'google');
});

test('Google: email ya registrado con contraseña se vincula y la contraseña se borra', async () => {
  const links = [];
  repo.findUserByEmail = async () => ana;
  repo.linkProviderToExistingUser = async (link) => {
    links.push(link);
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  // Una sola llamada que vincula y deja la cuenta sin contraseña: quien la
  // hubiera registrado con el correo de otro pierde el acceso.
  assert.deepEqual(links, [
    { userId: 7, provider: 'google', providerUserId: 'sub-1', email: 'ana@gmail.com' },
  ]);
  assert.equal(session.user.userId, 7);
  assert.deepEqual(eventTypes(), ['ACCOUNT_LINKED', 'LOGIN']);
});

test('Google: email vinculado a otra cuenta de Google responde 409', async () => {
  repo.findUserByEmail = async () => ana;
  repo.findProviderLink = async () => ({ providerUserId: 'otro-sub' });

  await assert.rejects(loginWithGoogle({ idToken: 'tok' }), {
    status: 409,
    code: 'GOOGLE_ACCOUNT_CONFLICT',
  });
});

test('Google: usuario nuevo se crea sin contraseña y pide el setup', async () => {
  const created = [];
  let lookups = 0;
  repo.findUserByProvider = async () => {
    lookups += 1;
    return lookups === 1 ? null : { ...ana, userId: 9, passwordHash: null, age: null };
  };
  repo.createUserWithProvider = async (data) => {
    created.push(data);
    return { userId: 9 };
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.deepEqual(created, [
    {
      name: 'Ana',
      email: 'ana@gmail.com',
      passwordHash: null,
      goal: null,
      roleId: 2,
      planId: 1,
      provider: 'google',
      providerUserId: 'sub-1',
    },
  ]);
  assert.equal(session.user.userId, 9);
  assert.equal(session.needsProfileSetup, true);
  assert.deepEqual(eventTypes(), ['REGISTER', 'LOGIN']);
  assert.equal(events[0].metadata.method, 'google');
});

test('Google: sin nombre usa la parte local del email', async () => {
  googleProfile = { ...googleProfile, name: '  ' };
  const created = [];
  let lookups = 0;
  repo.findUserByProvider = async () => (++lookups === 1 ? null : { ...ana, age: null });
  repo.createUserWithProvider = async (data) => {
    created.push(data);
    return { userId: 7 };
  };

  await loginWithGoogle({ idToken: 'tok' });

  assert.equal(created[0].name, 'ana');
});

test('Google: email no verificado responde 403', async () => {
  googleProfile = { ...googleProfile, emailVerified: false };

  await assert.rejects(loginWithGoogle({ idToken: 'tok' }), {
    status: 403,
    code: 'GOOGLE_EMAIL_NOT_VERIFIED',
  });
});

test('Google: si dos logins chocan con un UNIQUE, se reintenta la búsqueda', async () => {
  let lookups = 0;
  repo.findUserByProvider = async () => (++lookups === 1 ? null : ana);
  repo.createUserWithProvider = async () => {
    throw Object.assign(new Error('duplicate key'), { code: '23505' });
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.equal(session.user.userId, 7);
  assert.equal(lookups, 2);
});

test('Email: cuenta sin contraseña responde 409 USE_GOOGLE_SIGN_IN', async () => {
  repo.findUserByEmail = async () => ({ ...ana, passwordHash: null });

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'loquesea' }), {
    status: 409,
    code: 'USE_GOOGLE_SIGN_IN',
  });
  assert.deepEqual(eventTypes(), ['LOGIN_FAILED']);
  assert.equal(events[0].metadata.reason, 'USE_GOOGLE_SIGN_IN');
});

test('Email: la respuesta incluye needsProfileSetup', async () => {
  const passwordHash = await bcrypt.hash('secreto123', 4);
  repo.findUserByEmail = async () => ({ ...ana, passwordHash, age: null });

  const session = await loginUser({ email: 'ana@gmail.com', password: 'secreto123' });

  assert.equal(session.needsProfileSetup, true);
  assert.equal(session.user.passwordHash, undefined);
});
