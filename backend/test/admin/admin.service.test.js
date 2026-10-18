import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = [
  'expireGiftedPro',
  'findUserDetail',
  'findUsers',
  'getOverview',
  'updateUserPassword',
  'updateUserRole',
];

const repo = {};
const events = [];

mock.module(src('modules/admin/admin.repository.js'), {
  exports: {
    PANEL_TIMEZONE: 'America/Bogota',
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

let saveGiftImpl;
mock.module(src('modules/subscription/subscription.service.js'), {
  exports: { saveGift: (...args) => saveGiftImpl(...args) },
});

const {
  deleteUserService,
  getOverviewService,
  getUserDetailService,
  updateUserPasswordService,
  updateUserPlanService,
  updateUserRoleService,
} = await import(src('modules/admin/admin.service.js'));

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

const NOW = new Date('2026-10-17T15:00:00Z');

// Corre giftFor con el regalo indicado y devuelve el regalo nuevo.
const giftAfter = async (current, plan, duration) => {
  let gift;
  saveGiftImpl = async (userId, giftFor, now) => {
    gift = giftFor({ plan: 'FREE', storeExpiresAt: null, ...current });
    return { userId, plan: 'PRO', proUntil: null, proSource: 'gift', now };
  };
  await updateUserPlanService(5, plan, duration, NOW);
  return { ...gift, giftProUntil: gift.giftProUntil?.toISOString() ?? null };
};

test('plan: regalar 7 días a quien no tiene regalo', async () => {
  assert.deepEqual(await giftAfter({ giftPro: false, giftProUntil: null }, 'PRO', '7d'), {
    giftPro: true,
    giftProUntil: '2026-10-24T15:00:00.000Z',
  });
});

test('plan: extender un regalo con fecha suma a esa fecha', async () => {
  const gift = await giftAfter({ giftPro: true, giftProUntil: new Date('2026-11-01T00:00:00Z') }, 'PRO', '1m');
  assert.equal(gift.giftProUntil, '2026-12-01T00:00:00.000Z');
});

test('plan: el regalo cuenta desde ahora aunque pague en la tienda', async () => {
  const gift = await giftAfter(
    { plan: 'PRO', giftPro: false, giftProUntil: null, storeExpiresAt: new Date('2026-12-01T00:00:00Z') },
    'PRO',
    '7d'
  );
  assert.equal(gift.giftProUntil, '2026-10-24T15:00:00.000Z');
});

test('plan: regalo sin vencimiento', async () => {
  assert.deepEqual(await giftAfter({ giftPro: false, giftProUntil: null }, 'PRO', 'forever'), {
    giftPro: true,
    giftProUntil: null,
  });
});

test('plan: FREE quita el regalo', async () => {
  assert.deepEqual(await giftAfter({ giftPro: true, giftProUntil: new Date('2026-11-01T00:00:00Z') }, 'FREE'), {
    giftPro: false,
    giftProUntil: null,
  });
});

test('plan: devuelve lo que calculó saveGift y le pasa la hora', async () => {
  saveGiftImpl = async (userId, giftFor, now) => ({ userId, plan: 'PRO', proUntil: null, proSource: 'both', now });

  const result = await updateUserPlanService(5, 'FREE', undefined, NOW);

  assert.equal(result.proSource, 'both');
  assert.equal(result.now, NOW);
});

test('plan: usuario inexistente responde 404', async () => {
  saveGiftImpl = async () => null;

  await assert.rejects(updateUserPlanService(99, 'PRO', '7d', NOW), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});

// 01:00 UTC del 18 = 20:00 del 17 en Bogotá: el "hoy" del panel es el 17.
const NIGHT_IN_BOGOTA = new Date('2026-10-18T01:00:00Z');

test('detalle: agrega el resumen del agua con el hoy de Bogotá', async () => {
  repo.findUserDetail = async () => ({
    profile: { userId: 5 },
    usage: {},
    series: [],
    byModule: [],
    recentEvents: [],
    waterRows: [
      { day: '2026-10-16', glasses: 4 },
      { day: '2026-10-17', glasses: 2 },
    ],
  });

  const detail = await getUserDetailService(5, NIGHT_IN_BOGOTA);

  assert.equal(detail.waterRows, undefined);
  assert.equal(detail.water.today, '2026-10-17');
  assert.equal(detail.water.glassesToday, 2);
  assert.equal(detail.water.currentStreak, 1);
  assert.equal(detail.water.daysLogged, 2);
});

test('detalle: usuario inexistente responde 404', async () => {
  repo.findUserDetail = async () => null;

  await assert.rejects(getUserDetailService(99, NIGHT_IN_BOGOTA), { status: 404, code: 'USER_NOT_FOUND' });
});

test('resumen: cuenta las rachas de agua vivas y las ordena', async () => {
  const calls = [];
  repo.getOverview = async (...args) => {
    calls.push(args);
    return {
      days: 30,
      users: {},
      water: { users: 3, usersInRange: 3 },
      waterStreakRows: [
        // 2 días seguidos, hoy a medias.
        { userId: 1, name: 'Ana', plan: 'FREE', day: '2026-10-15', glasses: 4 },
        { userId: 1, name: 'Ana', plan: 'FREE', day: '2026-10-16', glasses: 4 },
        { userId: 1, name: 'Ana', plan: 'FREE', day: '2026-10-17', glasses: 1 },
        // 3 días seguidos hasta hoy.
        { userId: 2, name: 'Bea', plan: 'PRO', day: '2026-10-15', glasses: 4 },
        { userId: 2, name: 'Bea', plan: 'PRO', day: '2026-10-16', glasses: 4 },
        { userId: 2, name: 'Bea', plan: 'PRO', day: '2026-10-17', glasses: 4 },
      ],
    };
  };

  const overview = await getOverviewService(30, NIGHT_IN_BOGOTA);

  assert.deepEqual(calls, [[30, '2026-10-17']]);
  assert.equal(overview.waterStreakRows, undefined);
  assert.equal(overview.water.users, 3);
  assert.equal(overview.water.activeStreaks, 2);
  assert.deepEqual(overview.water.topStreaks, [
    { userId: 2, name: 'Bea', plan: 'PRO', currentStreak: 3 },
    { userId: 1, name: 'Ana', plan: 'FREE', currentStreak: 2 },
  ]);
});

test('detalle: agrega de dónde viene el PRO', async () => {
  repo.findUserDetail = async () => ({
    profile: {
      userId: 5,
      giftPro: false,
      giftProUntil: null,
      subscription: { expiresAt: '2026-11-17T15:00:00Z', productId: 'monthly' },
    },
    usage: {},
    series: [],
    byModule: [],
    recentEvents: [],
    waterRows: [],
  });

  const detail = await getUserDetailService(5, NIGHT_IN_BOGOTA);

  assert.equal(detail.profile.proSource, 'store');
  assert.equal(detail.profile.subscription.productId, 'monthly');
});

test('detalle: sin suscripción ni regalo no hay proSource', async () => {
  repo.findUserDetail = async () => ({
    profile: { userId: 5, giftPro: false, giftProUntil: null, subscription: null },
    usage: {},
    series: [],
    byModule: [],
    recentEvents: [],
    waterRows: [],
  });

  const detail = await getUserDetailService(5, NIGHT_IN_BOGOTA);

  assert.equal(detail.profile.proSource, null);
});
