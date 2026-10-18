import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const { AppError } = await import(src('utils/AppError.js'));

const REPO_EXPORTS = [
  'createPhysicalRecord',
  'deleteUserAccountData',
  'findPhysicalHistoryByUserId',
  'findUserCredentialsById',
  'findUserProfileById',
  'setPasswordIfMissing',
  'updateUserProfileData',
];

const repo = {};
const events = [];
let verifyImpl;

mock.module(src('modules/user/user.repository.js'), {
  exports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/events/events.service.js'), {
  exports: {
    logEventService: async (event) => {
      events.push(event);
    },
  },
});
mock.module(src('modules/auth/google.verifier.js'), {
  exports: { verifyGoogleIdToken: (...args) => verifyImpl(...args) },
});

const { deleteUserAccount, getUserProfile, setUserPassword } = await import(src('modules/user/user.service.js'));

const passwordHash = await bcrypt.hash('secreto123', 4);
let deletedIds;

beforeEach(() => {
  deletedIds = [];
  events.length = 0;
  repo.deleteUserAccountData = async (userId) => {
    deletedIds.push(userId);
    return true;
  };
  verifyImpl = async () => ({ sub: 'sub-1', email: 'ana@gmail.com', emailVerified: true, name: 'Ana' });
});

test('cuenta con contraseña: borra con la contraseña correcta', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: null });

  await deleteUserAccount(7, { password: 'secreto123' });

  assert.deepEqual(deletedIds, [7]);
});

test('cuenta con contraseña: contraseña incorrecta responde 403', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { password: 'otra' }), {
    status: 403,
    code: 'INVALID_PASSWORD',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta con contraseña: con googleIdToken en vez de contraseña responde 400', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 400,
    code: 'VALIDATION_ERROR',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta solo de Google: borra si el sub coincide', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });

  await deleteUserAccount(7, { googleIdToken: 'tok' });

  assert.deepEqual(deletedIds, [7]);
});

test('cuenta solo de Google: otro sub responde 403 GOOGLE_ACCOUNT_MISMATCH', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  verifyImpl = async () => ({ sub: 'sub-2', email: 'otro@gmail.com', emailVerified: true, name: null });

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 403,
    code: 'GOOGLE_ACCOUNT_MISMATCH',
  });
  assert.deepEqual(deletedIds, []);
});

test('cuenta solo de Google: token inválido responde 403, no 401', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  verifyImpl = async () => {
    throw new AppError('No se pudo verificar tu cuenta de Google.', 401, 'INVALID_GOOGLE_TOKEN');
  };

  await assert.rejects(deleteUserAccount(7, { googleIdToken: 'tok' }), {
    status: 403,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('cuenta solo de Google: sin googleIdToken responde 400', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });

  await assert.rejects(deleteUserAccount(7, { password: 'secreto123' }), {
    status: 400,
    code: 'VALIDATION_ERROR',
  });
});

test('usuario inexistente responde 404', async () => {
  repo.findUserCredentialsById = async () => null;

  await assert.rejects(deleteUserAccount(7, { password: 'secreto123' }), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});

test('crear contraseña: una cuenta solo de Google guarda el hash de la nueva', async () => {
  const saved = [];
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  repo.setPasswordIfMissing = async (userId, hash) => {
    saved.push({ userId, hash });
    return { userId };
  };

  await setUserPassword(7, 'nueva123');

  assert.equal(saved[0].userId, 7);
  assert.equal(await bcrypt.compare('nueva123', saved[0].hash), true);
  assert.equal(events.at(-1).eventType, 'PASSWORD_SET');
  assert.equal(events.at(-1).userId, 7);
});

test('crear contraseña: si ya tiene una responde 409 y no la cambia', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash, googleSub: 'sub-1' });
  repo.setPasswordIfMissing = async () => {
    throw new Error('setPasswordIfMissing no debería llamarse');
  };

  await assert.rejects(setUserPassword(7, 'nueva123'), {
    status: 409,
    code: 'PASSWORD_ALREADY_SET',
  });
});

test('crear contraseña: si otra petición la creó antes responde 409', async () => {
  repo.findUserCredentialsById = async () => ({ passwordHash: null, googleSub: 'sub-1' });
  repo.setPasswordIfMissing = async () => null;

  await assert.rejects(setUserPassword(7, 'nueva123'), {
    status: 409,
    code: 'PASSWORD_ALREADY_SET',
  });
});

test('crear contraseña: usuario inexistente responde 404', async () => {
  repo.findUserCredentialsById = async () => null;

  await assert.rejects(setUserPassword(7, 'nueva123'), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});

test('perfil: agrega proSource y no expone los datos internos del plan', async () => {
  repo.findUserProfileById = async () => ({
    userId: 7,
    plan: 'PRO',
    proUntil: null,
    giftPro: true,
    giftProUntil: null,
    storeExpiresAt: null,
  });

  const profile = await getUserProfile(7);

  assert.equal(profile.proSource, 'gift');
  assert.equal('giftPro' in profile, false);
  assert.equal('giftProUntil' in profile, false);
  assert.equal('storeExpiresAt' in profile, false);
});
