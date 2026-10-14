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
  'updateUserProfileData',
];

const repo = {};
let verifyImpl;

mock.module(src('modules/user/user.repository.js'), {
  exports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/events/events.service.js'), {
  exports: { logEventService: async () => {} },
});
mock.module(src('modules/auth/google.verifier.js'), {
  exports: { verifyGoogleIdToken: (...args) => verifyImpl(...args) },
});

const { deleteUserAccount } = await import(src('modules/user/user.service.js'));

const passwordHash = await bcrypt.hash('secreto123', 4);
let deletedIds;

beforeEach(() => {
  deletedIds = [];
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
