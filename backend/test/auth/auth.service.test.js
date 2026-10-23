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
  'linkAuthProvider',
  'markEmailVerified',
  'setPasswordAndVerify',
];

const repo = {};
const events = [];
let googleProfile;

mock.module(src('modules/auth/auth.repository.js'), {
  exports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/auth/guest.repository.js'), {
  exports: {
    findSampleFoodIds: async () => [],
    createGuestAccount: async () => 0,
    findExpiredGuestIds: async () => [],
    countActiveGuests: async () => 0,
  },
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
const codes = {};
mock.module(src('modules/auth/email-code.service.js'), {
  exports: {
    CODE_PURPOSE: { VERIFY_EMAIL: 'verify_email', RESET_PASSWORD: 'reset_password' },
    sendCode: (...args) => codes.sendCode(...args),
    consumeCode: (...args) => codes.consumeCode(...args),
  },
});

const { config } = await import(src('config/env_config.js'));
const {
  forgotPassword,
  linkGoogleAccount,
  loginUser,
  loginWithGoogle,
  registerUser,
  resendVerification,
  resetPassword,
  verifyEmail,
} = await import(src('modules/auth/auth.service.js'));

const ana = {
  userId: 7,
  name: 'Ana',
  email: 'ana@gmail.com',
  passwordHash: 'hash',
  goal: null,
  age: 30,
  role: 'USER',
  plan: 'FREE',
  emailVerifiedAt: new Date('2026-01-01'),
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
    linkAuthProvider: fail('linkAuthProvider'),
    markEmailVerified: fail('markEmailVerified'),
    setPasswordAndVerify: fail('setPasswordAndVerify'),
  });
  Object.assign(codes, {
    sendCode: fail('sendCode'),
    consumeCode: fail('consumeCode'),
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
  assert.equal(session.offerPasswordSetup, false);
  assert.deepEqual(eventTypes(), ['LOGIN']);
  assert.equal(events[0].metadata.method, 'google');
});

test('Google: email ya registrado con contraseña pide la contraseña y no vincula', async () => {
  repo.findUserByEmail = async () => ana;

  // Sin la contraseña no se sabe si la cuenta es de quien entra con Google:
  // el registro con email no verifica el correo.
  await assert.rejects(loginWithGoogle({ idToken: 'tok' }), {
    status: 409,
    code: 'GOOGLE_LINK_REQUIRES_PASSWORD',
  });
  assert.deepEqual(eventTypes(), []);
});

test('Google: una cuenta sin contraseña ni Google se vincula directo', async () => {
  const links = [];
  repo.findUserByEmail = async () => ({ ...ana, passwordHash: null });
  repo.linkAuthProvider = async (link) => {
    links.push(link);
  };

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.deepEqual(links, [
    { userId: 7, provider: 'google', providerUserId: 'sub-1', email: 'ana@gmail.com' },
  ]);
  assert.equal(session.user.userId, 7);
  assert.equal(session.offerPasswordSetup, true);
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

  const { emailVerifiedAt, ...createdData } = created[0];
  assert.deepEqual(createdData, {
    name: 'Ana',
    email: 'ana@gmail.com',
    passwordHash: null,
    goal: null,
    roleId: 2,
    planId: 1,
    provider: 'google',
    providerUserId: 'sub-1',
  });
  // Google ya verificó el correo.
  assert.ok(emailVerifiedAt instanceof Date);
  assert.equal(session.user.userId, 9);
  assert.equal(session.needsProfileSetup, true);
  assert.equal(session.offerPasswordSetup, true);
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

test('Email: cuenta sin contraseña no se distingue de credenciales inválidas', async () => {
  repo.findUserByEmail = async () => ({ ...ana, passwordHash: null });

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'loquesea' }), {
    status: 401,
    code: 'INVALID_CREDENTIALS',
  });
  assert.deepEqual(eventTypes(), ['LOGIN_FAILED']);
  assert.equal(events[0].metadata.reason, 'USE_GOOGLE_SIGN_IN');
});

test('Email: correo inexistente y contraseña incorrecta tienen la misma respuesta', async () => {
  const passwordHash = await bcrypt.hash('secreto123', 4);
  repo.findUserByEmail = async () => null;
  await assert.rejects(loginUser({ email: 'nadie@gmail.com', password: 'otra' }), {
    status: 401,
    code: 'INVALID_CREDENTIALS',
    message: 'Invalid credentials',
  });

  repo.findUserByEmail = async () => ({ ...ana, passwordHash });
  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'otra' }), {
    status: 401,
    code: 'INVALID_CREDENTIALS',
    message: 'Invalid credentials',
  });
});

test('Sesión: usuario conserva JWT por 30 días y admin por 1 hora', async () => {
  const passwordHash = await bcrypt.hash('secreto123', 4);
  for (const [role, expectedSeconds] of [['USER', 30 * 24 * 60 * 60], ['ADMIN', 60 * 60]]) {
    repo.findUserByEmail = async () => ({ ...ana, role, passwordHash });
    const session = await loginUser({ email: 'ana@gmail.com', password: 'secreto123' });
    const { iat, exp } = jwt.verify(session.token, 'test_secret');
    assert.equal(exp - iat, expectedSeconds);
  }
});

test('Email: la respuesta incluye needsProfileSetup', async () => {
  const passwordHash = await bcrypt.hash('secreto123', 4);
  repo.findUserByEmail = async () => ({ ...ana, passwordHash, age: null });

  const session = await loginUser({ email: 'ana@gmail.com', password: 'secreto123' });

  assert.equal(session.needsProfileSetup, true);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.offerPasswordSetup, undefined);
});

test('Google: una cuenta solo de Google que vuelve a entrar no recibe la oferta otra vez', async () => {
  repo.findUserByProvider = async () => ({ ...ana, passwordHash: null });

  const session = await loginWithGoogle({ idToken: 'tok' });

  assert.equal(session.offerPasswordSetup, false);
});

const anaWithPassword = async () => ({
  ...ana,
  passwordHash: await bcrypt.hash('secreto123', 4),
});

test('Vincular: con la contraseña correcta vincula sin borrarla', async () => {
  const links = [];
  const user = await anaWithPassword();
  repo.findUserByEmail = async () => user;
  repo.linkAuthProvider = async (link) => {
    links.push(link);
  };

  const session = await linkGoogleAccount({ idToken: 'tok', password: 'secreto123' });

  assert.deepEqual(links, [
    { userId: 7, provider: 'google', providerUserId: 'sub-1', email: 'ana@gmail.com' },
  ]);
  assert.equal(jwt.verify(session.token, 'test_secret').userId, 7);
  assert.equal(session.user.passwordHash, undefined);
  assert.equal(session.offerPasswordSetup, false);
  assert.deepEqual(eventTypes(), ['ACCOUNT_LINKED', 'LOGIN']);
  assert.equal(events[1].metadata.method, 'google');
});

test('Vincular: contraseña incorrecta responde 401 y no vincula', async () => {
  const user = await anaWithPassword();
  repo.findUserByEmail = async () => user;

  await assert.rejects(linkGoogleAccount({ idToken: 'tok', password: 'otra' }), {
    status: 401,
    code: 'INVALID_PASSWORD',
  });
  assert.deepEqual(eventTypes(), ['LOGIN_FAILED']);
  assert.deepEqual(events[0].metadata, {
    email: 'ana@gmail.com',
    reason: 'INVALID_PASSWORD',
    method: 'google-link',
  });
});

test('Vincular: si el sub ya está vinculado inicia sesión sin pedir nada más', async () => {
  repo.findUserByProvider = async () => ana;

  const session = await linkGoogleAccount({ idToken: 'tok', password: 'loquesea' });

  assert.equal(session.user.userId, 7);
  assert.deepEqual(eventTypes(), ['LOGIN']);
});

test('Vincular: sin cuenta con ese correo responde 404', async () => {
  await assert.rejects(linkGoogleAccount({ idToken: 'tok', password: 'secreto123' }), {
    status: 404,
    code: 'USER_NOT_FOUND',
  });
});

test('Vincular: correo con otra cuenta de Google responde 409', async () => {
  const user = await anaWithPassword();
  repo.findUserByEmail = async () => user;
  repo.findProviderLink = async () => ({ providerUserId: 'otro-sub' });

  await assert.rejects(linkGoogleAccount({ idToken: 'tok', password: 'secreto123' }), {
    status: 409,
    code: 'GOOGLE_ACCOUNT_CONFLICT',
  });
});

test('Vincular: correo de Google no verificado responde 403', async () => {
  googleProfile = { ...googleProfile, emailVerified: false };

  await assert.rejects(linkGoogleAccount({ idToken: 'tok', password: 'secreto123' }), {
    status: 403,
    code: 'GOOGLE_EMAIL_NOT_VERIFIED',
  });
});

// --- Verificación del correo y restablecer contraseña ---

const unverifiedAna = async () => ({
  ...ana,
  passwordHash: await bcrypt.hash('secreto123', 4),
  emailVerifiedAt: null,
});

test('Registro: crea la cuenta sin verificar y envía el código', async () => {
  const created = [];
  const sent = [];
  repo.createUser = async (data) => {
    created.push(data);
    return { userId: 11, name: data.name, email: data.email };
  };
  codes.sendCode = async (user, purpose) => {
    sent.push({ user, purpose });
  };

  const result = await registerUser({
    name: 'Ana',
    email: 'ana@gmail.com',
    password: 'secreto123',
    goal: null,
  });

  assert.equal(created[0].emailVerifiedAt, null);
  assert.equal(sent[0].purpose, 'verify_email');
  assert.equal(sent[0].user.email, 'ana@gmail.com');
  assert.equal(result.verificationRequired, true);
});

test('Registro: si el correo no se puede enviar la cuenta igual se crea', async () => {
  mock.method(console, 'error', () => {});
  repo.createUser = async (data) => ({ userId: 11, name: data.name, email: data.email });
  codes.sendCode = async () => {
    throw new Error('Resend caído');
  };

  const result = await registerUser({
    name: 'Ana',
    email: 'ana@gmail.com',
    password: 'secreto123',
    goal: null,
  });

  assert.equal(result.userId, 11);
  assert.equal(result.verificationRequired, true);
  mock.restoreAll();
});

test('Login: correo sin verificar envía un código y responde 403', async () => {
  const sent = [];
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;
  codes.sendCode = async (u, purpose) => {
    sent.push(purpose);
  };

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'secreto123' }), {
    status: 403,
    code: 'EMAIL_NOT_VERIFIED',
  });
  assert.deepEqual(sent, ['verify_email']);
  assert.equal(events.at(-1).metadata.reason, 'EMAIL_NOT_VERIFIED');
});

test('Login: sin verificar envía el código en el idioma de la petición', async () => {
  const langs = [];
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;
  codes.sendCode = async (u, purpose, lang) => {
    langs.push(lang);
  };

  await assert.rejects(
    loginUser({ email: 'ana@gmail.com', password: 'secreto123', lang: 'en' }),
    { code: 'EMAIL_NOT_VERIFIED' }
  );
  assert.deepEqual(langs, ['en']);
});

test('Login: sin verificar y con un código reciente igual responde 403', async () => {
  const { AppError } = await import(src('utils/AppError.js'));
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;
  codes.sendCode = async () => {
    throw new AppError('Espera', 429, 'CODE_RECENTLY_SENT');
  };

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'secreto123' }), {
    status: 403,
    code: 'EMAIL_NOT_VERIFIED',
  });
});

test('Login: sin verificar y con contraseña incorrecta no envía código', async () => {
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;

  await assert.rejects(loginUser({ email: 'ana@gmail.com', password: 'otra' }), {
    status: 401,
    code: 'INVALID_CREDENTIALS',
  });
});

test('Verificar: código correcto marca el correo y devuelve la sesión', async () => {
  const marked = [];
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;
  codes.consumeCode = async (userId, purpose, code) => {
    assert.deepEqual([userId, purpose, code], [7, 'verify_email', '482913']);
  };
  repo.markEmailVerified = async (userId) => {
    marked.push(userId);
  };

  const session = await verifyEmail({ email: 'ana@gmail.com', code: '482913' });

  assert.deepEqual(marked, [7]);
  assert.equal(jwt.verify(session.token, 'test_secret').userId, 7);
  assert.equal(session.user.passwordHash, undefined);
  assert.ok(session.user.emailVerifiedAt);
  assert.deepEqual(eventTypes(), ['EMAIL_VERIFIED', 'LOGIN']);
});

test('Verificar: correo inexistente responde 400 INVALID_CODE', async () => {
  await assert.rejects(verifyEmail({ email: 'nadie@gmail.com', code: '482913' }), {
    status: 400,
    code: 'INVALID_CODE',
  });
});

test('Reenviar verificación: solo envía a cuentas sin verificar', async () => {
  const sent = [];
  codes.sendCode = async (user, purpose) => {
    sent.push(purpose);
  };

  repo.findUserByEmail = async () => unverifiedAna();
  await resendVerification({ email: 'ana@gmail.com' });
  repo.findUserByEmail = async () => ana;
  await resendVerification({ email: 'ana@gmail.com' });
  repo.findUserByEmail = async () => null;
  await resendVerification({ email: 'nadie@gmail.com' });

  assert.deepEqual(sent, ['verify_email']);
});

test('Olvidé mi contraseña: envía el código si la cuenta existe y no revela si no', async () => {
  const sent = [];
  codes.sendCode = async (user, purpose) => {
    sent.push(purpose);
  };

  repo.findUserByEmail = async () => ana;
  await forgotPassword({ email: 'ana@gmail.com' });
  repo.findUserByEmail = async () => null;
  await forgotPassword({ email: 'nadie@gmail.com' });

  assert.deepEqual(sent, ['reset_password']);
});

test('Olvidé mi contraseña y reenvío: nunca mandan correo a un invitado', async () => {
  const sent = [];
  codes.sendCode = async (user, purpose) => {
    sent.push(purpose);
  };
  const guest = { ...ana, email: 'guest-1b2c@guest.nutrilife.invalid', emailVerifiedAt: null };

  repo.findUserByEmail = async () => guest;
  await forgotPassword({ email: guest.email });
  await resendVerification({ email: guest.email });

  assert.deepEqual(sent, []);
});

test('Restablecer: código correcto guarda la contraseña nueva', async () => {
  const saved = [];
  repo.findUserByEmail = async () => ana;
  codes.consumeCode = async (userId, purpose) => {
    assert.deepEqual([userId, purpose], [7, 'reset_password']);
  };
  repo.setPasswordAndVerify = async (userId, hash) => {
    saved.push({ userId, hash });
  };

  await resetPassword({ email: 'ana@gmail.com', code: '482913', password: 'nueva123' });

  assert.equal(saved[0].userId, 7);
  assert.equal(await bcrypt.compare('nueva123', saved[0].hash), true);
  assert.deepEqual(eventTypes(), ['PASSWORD_RESET']);
});

test('Restablecer: correo inexistente responde 400 INVALID_CODE', async () => {
  await assert.rejects(
    resetPassword({ email: 'nadie@gmail.com', code: '482913', password: 'nueva123' }),
    { status: 400, code: 'INVALID_CODE' }
  );
});

test('Vincular: una cuenta sin verificar queda verificada', async () => {
  const marked = [];
  const user = await unverifiedAna();
  repo.findUserByEmail = async () => user;
  repo.linkAuthProvider = async () => {};
  repo.markEmailVerified = async (userId) => {
    marked.push(userId);
  };

  await linkGoogleAccount({ idToken: 'tok', password: 'secreto123' });

  assert.deepEqual(marked, [7]);
});

test('Registro, reenvío y olvidé mi contraseña pasan el idioma a sendCode', async () => {
  const langs = [];
  codes.sendCode = async (user, purpose, lang) => {
    langs.push([purpose, lang]);
  };
  repo.createUser = async (data) => ({ userId: 11, name: data.name, email: data.email });

  await registerUser({ name: 'Ana', email: 'ana@gmail.com', password: 'secreto123', goal: null, lang: 'en' });
  repo.findUserByEmail = async () => unverifiedAna();
  await resendVerification({ email: 'ana@gmail.com', lang: 'en' });
  await forgotPassword({ email: 'ana@gmail.com', lang: 'en' });

  assert.deepEqual(langs, [
    ['verify_email', 'en'],
    ['verify_email', 'en'],
    ['reset_password', 'en'],
  ]);
});
