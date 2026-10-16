import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = [
  'findUserDetail',
  'findUsers',
  'getOverview',
  'updateUserPassword',
  'updateUserPlan',
  'updateUserRole',
];

const repo = {};
const events = [];

mock.module(src('modules/admin/admin.repository.js'), {
  exports: {
    USER_SORT_KEYS: ['recent'],
    ...Object.fromEntries(REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])),
  },
});
mock.module(src('modules/user/user.repository.js'), {
  exports: { deleteUserAccountData: (...args) => repo.deleteUserAccountData(...args) },
});
mock.module(src('modules/events/events.service.js'), {
  exports: {
    logEventService: async (event) => {
      events.push(event);
    },
  },
});

const { deleteUserService, updateUserPasswordService, updateUserRoleService } = await import(
  src('modules/admin/admin.service.js')
);

const ADMIN_ID = 1;

beforeEach(() => {
  events.length = 0;
});

test('contraseña: guarda un hash bcrypt de la contraseña nueva', async () => {
  const saved = [];
  repo.updateUserPassword = async (userId, passwordHash) => {
    saved.push({ userId, passwordHash });
    return { userId };
  };

  const result = await updateUserPasswordService(ADMIN_ID, 9, 'nueva123');

  assert.deepEqual(result, { userId: 9 });
  assert.equal(saved[0].userId, 9);
  assert.notEqual(saved[0].passwordHash, 'nueva123');
  assert.equal(await bcrypt.compare('nueva123', saved[0].passwordHash), true);
  assert.equal(events[0].eventType, 'PASSWORD_RESET_BY_ADMIN');
  assert.equal(events[0].userId, 9);
  assert.equal(events[0].metadata.by, ADMIN_ID);
});

test('contraseña: usuario inexistente responde 404', async () => {
  repo.updateUserPassword = async () => null;

  await assert.rejects(updateUserPasswordService(ADMIN_ID, 99, 'nueva123'), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
  assert.deepEqual(events, []);
});

test('rol: da el rol ADMIN a otro usuario', async () => {
  repo.updateUserRole = async (userId, role) => ({ userId, role });

  const result = await updateUserRoleService(ADMIN_ID, 9, 'ADMIN');

  assert.deepEqual(result, { userId: 9, role: 'ADMIN' });
  assert.equal(events[0].eventType, 'ROLE_CHANGED');
  assert.deepEqual(events[0].metadata, { role: 'ADMIN', by: ADMIN_ID });
});

test('rol: un admin no puede quitarse el rol a sí mismo', async () => {
  repo.updateUserRole = async () => {
    throw new Error('updateUserRole no debería llamarse');
  };

  await assert.rejects(updateUserRoleService(ADMIN_ID, ADMIN_ID, 'USER'), {
    status: 409,
    code: 'CANNOT_DEMOTE_SELF',
  });
});

test('rol: usuario inexistente responde 404', async () => {
  repo.updateUserRole = async () => null;

  await assert.rejects(updateUserRoleService(ADMIN_ID, 99, 'USER'), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});

test('eliminar: borra la cuenta y deja el evento sin datos del usuario', async () => {
  const deleted = [];
  repo.deleteUserAccountData = async (userId) => {
    deleted.push(userId);
    return true;
  };

  await deleteUserService(ADMIN_ID, 9);

  assert.deepEqual(deleted, [9]);
  assert.equal(events[0].eventType, 'ACCOUNT_DELETED');
  assert.equal(events[0].userId, null);
  assert.deepEqual(events[0].metadata, { by: ADMIN_ID });
});

test('eliminar: un admin no puede borrar su propia cuenta desde el panel', async () => {
  repo.deleteUserAccountData = async () => {
    throw new Error('deleteUserAccountData no debería llamarse');
  };

  await assert.rejects(deleteUserService(ADMIN_ID, ADMIN_ID), {
    status: 409,
    code: 'CANNOT_DELETE_SELF',
  });
});

test('eliminar: usuario inexistente responde 404', async () => {
  repo.deleteUserAccountData = async () => false;

  await assert.rejects(deleteUserService(ADMIN_ID, 99), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
  assert.deepEqual(events, []);
});
