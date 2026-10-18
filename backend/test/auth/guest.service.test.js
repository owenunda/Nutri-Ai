import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
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
  'linkAuthProvider',
  'markEmailVerified',
  'setPasswordAndVerify',
];

const repo = {};
const guestRepo = {};
const events = [];
const fridges = [];

mock.module(src('modules/auth/auth.repository.js'), {
  exports: Object.fromEntries(REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])),
});
mock.module(src('modules/auth/guest.repository.js'), {
  exports: {
    findSampleFoodIds: (...args) => guestRepo.findSampleFoodIds(...args),
    createGuestAccount: (...args) => guestRepo.createGuestAccount(...args),
    findExpiredGuestIds: async () => [],
    countActiveGuests: (...args) => guestRepo.countActiveGuests(...args),
  },
});
mock.module(src('modules/fridge/fridge.service.js'), {
  exports: { createFridgeService: async (userId) => { fridges.push(userId); } },
});
mock.module(src('modules/events/events.service.js'), {
  exports: { logEventService: async (event) => { events.push(event); } },
});
mock.module(src('modules/auth/google.verifier.js'), {
  exports: { verifyGoogleIdToken: async () => null },
});
mock.module(src('modules/auth/email-code.service.js'), {
  exports: {
    CODE_PURPOSE: { VERIFY_EMAIL: 'verify_email', RESET_PASSWORD: 'reset_password' },
    sendCode: async () => {},
    consumeCode: async () => {},
  },
});

const { config } = await import(src('config/env_config.js'));
const { loginAsGuest, getAuthModuleStatus } = await import(src('modules/auth/auth.service.js'));

let created;

beforeEach(() => {
  config.jwt.secret = 'test-secret';
  config.guestMode.enabled = true;
  events.length = 0;
  fridges.length = 0;
  created = null;
  repo.getDefaultRoleAndPlanIds = async () => ({ roleId: 2, planId: 1 });
  repo.getAuthRepositoryStatus = async () => ({ ok: true });
  guestRepo.countActiveGuests = async () => 0;
  guestRepo.findSampleFoodIds = async () => [5, 6];
  guestRepo.createGuestAccount = async (input) => {
    created = input;
    return 41;
  };
  repo.findUserByEmail = async (email) => ({
    userId: 41,
    name: created.user.name,
    email,
    passwordHash: null,
    goal: 'lose',
    age: 28,
    emailVerifiedAt: created.user.emailVerifiedAt,
    role: 'USER',
    plan: 'FREE',
    guestExpiresAt: created.expiresAt,
  });
});

test('con el modo apagado responde 404', async () => {
  config.guestMode.enabled = false;
  await assert.rejects(loginAsGuest({ lang: 'es' }), { status: 404, code: 'GUEST_MODE_DISABLED' });
});

test('con el tope de invitados activos responde 503 y no crea nada', async () => {
  guestRepo.countActiveGuests = async () => config.guestMode.maxActive;
  await assert.rejects(loginAsGuest({ lang: 'es' }), { status: 503, code: 'GUEST_LIMIT_REACHED' });
  assert.equal(created, null);
  assert.deepEqual(fridges, []);
});

test('crea un invitado FREE, verificado, sin contraseña y que vence en 24 h', async () => {
  const before = Date.now();
  const session = await loginAsGuest({ lang: 'es' });

  assert.equal(created.user.name, 'Invitado');
  assert.match(created.user.email, /^guest-[0-9a-f-]{36}@guest\.nutrilife\.invalid$/);
  assert.equal(created.user.passwordHash, null);
  assert.equal(created.user.roleId, 2);
  assert.equal(created.user.planId, 1);
  assert.ok(created.user.emailVerifiedAt instanceof Date);
  const ttl = created.expiresAt.getTime() - before;
  assert.ok(ttl >= 24 * 60 * 60 * 1000 - 1000 && ttl <= 24 * 60 * 60 * 1000 + 1000);
  assert.equal(created.sample.meals.length, 7);
  assert.equal(created.profile.age, 28);

  assert.equal(session.user.isGuest, true);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.needsProfileSetup, false);
  assert.equal(session.guestExpiresAt, created.expiresAt);
  assert.deepEqual(fridges, [41]);
  assert.ok(events.some((e) => e.eventType === 'REGISTER' && e.metadata.method === 'guest'));
});

test('en inglés se llama Guest', async () => {
  await loginAsGuest({ lang: 'en' });
  assert.equal(created.user.name, 'Guest');
});

test('el token es de invitado y vence con la cuenta', async () => {
  const session = await loginAsGuest({ lang: 'es' });
  const payload = jwt.verify(session.token, 'test-secret');
  assert.equal(payload.isGuest, true);
  assert.ok(Math.abs(payload.exp - Math.floor(created.expiresAt.getTime() / 1000)) <= 2);
});

test('el health dice si el modo invitado está encendido', async () => {
  assert.equal((await getAuthModuleStatus()).guestModeEnabled, true);
  config.guestMode.enabled = false;
  assert.equal((await getAuthModuleStatus()).guestModeEnabled, false);
});
