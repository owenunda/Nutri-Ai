import { randomUUID } from 'node:crypto';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import {
  createUser,
  createUserWithProvider,
  findProviderLink,
  findUserByEmail,
  findUserByProvider,
  getAuthRepositoryStatus,
  getDefaultRoleAndPlanIds,
  linkAuthProvider,
  markEmailVerified,
  setPasswordAndVerify,
} from './auth.repository.js';
import { CODE_PURPOSE, consumeCode, sendCode } from './email-code.service.js';
import { countActiveGuests, createGuestAccount, findSampleFoodIds } from './guest.repository.js';
import { GUEST_PROFILE, GUEST_TTL_MS, buildGuestSampleData } from './guest.sampleData.js';
import { verifyGoogleIdToken } from './google.verifier.js';
import { createFridgeService } from '../fridge/fridge.service.js';
import { logEventService } from '../events/events.service.js';
import { bogotaDayKey } from '../../utils/bogotaDay.js';

const JWT_ADMIN_EXPIRES_IN = '1h';
const JWT_USER_EXPIRES_IN = '30d';
const SALT_ROUNDS = 10;
const GOOGLE = 'google';
const UNIQUE_VIOLATION = '23505';
export const GUEST_EMAIL_DOMAIN = 'guest.nutrilife.invalid';
const isGuestEmail = (email) => email?.endsWith(`@${GUEST_EMAIL_DOMAIN}`);
const GUEST_NAMES = { es: 'Invitado', en: 'Guest' };

export const getAuthModuleStatus = async () => {
  try {
    const repository = await getAuthRepositoryStatus();

    return {
      module: 'auth',
      status: 'running',
      repository,
      guestModeEnabled: config.guestMode.enabled,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

// El invitado no tiene contraseña para volver a entrar: su token dura lo que
// dura la cuenta, y al vencer el middleware responde GUEST_EXPIRED.
const tokenExpiry = (user) =>
  user.guestExpiresAt
    ? Math.max(1, Math.floor((new Date(user.guestExpiresAt).getTime() - Date.now()) / 1000))
    : user.role === 'ADMIN'
      ? JWT_ADMIN_EXPIRES_IN
      : JWT_USER_EXPIRES_IN;

const issueToken = (user) => {
  if (!config.jwt.secret) {
    throw new AppError('JWT secret is not configured', 500, 'AUTH_CONFIG_ERROR');
  }

  const tokenPayload = {
    userId: user.userId,
    email: user.email,
    role: user.role,
    plan: user.plan,
    name: user.name,
    goal: user.goal,
    ...(user.guestExpiresAt ? { isGuest: true } : {}),
  };

  return jwt.sign(tokenPayload, config.jwt.secret, { expiresIn: tokenExpiry(user) });
};

// Respuesta común de los logins. Sin edad, el usuario no terminó el setup
// del perfil y la app lo manda ahí en vez de al Dashboard. Las cuentas
// normales no llevan `guestExpiresAt` ni `isGuest`.
const buildSession = (user) => {
  const { passwordHash, guestExpiresAt, ...safeUser } = user;

  return {
    token: issueToken(user),
    user: guestExpiresAt ? { ...safeUser, isGuest: true, guestExpiresAt } : safeUser,
    needsProfileSetup: user.age == null,
  };
};

// Crea el usuario con el rol y plan por defecto y su nevera. Con `provider`,
// el usuario y su cuenta externa se crean en la misma transacción.
const createUserWithDefaults = async ({
  name,
  email,
  passwordHash = null,
  goal = null,
  provider = null,
  emailVerifiedAt = null,
}) => {
  const defaults = await getDefaultRoleAndPlanIds();

  if (!defaults?.roleId || !defaults?.planId) {
    throw new AppError('Default role or plan is not configured', 500, 'AUTH_DEFAULTS_NOT_FOUND');
  }

  const userData = {
    name,
    email,
    passwordHash,
    goal,
    roleId: Number(defaults.roleId),
    planId: Number(defaults.planId),
    emailVerifiedAt,
  };

  const newUser = provider
    ? await createUserWithProvider({ ...userData, ...provider })
    : await createUser(userData);

  await createFridgeService(newUser.userId);

  return newUser;
};

const logLogin = (user, metadata = {}) =>
  logEventService({
    eventType: 'LOGIN',
    category: 'AUTH',
    userId: user.userId,
    metadata: { email: user.email, role: user.role, ...metadata },
  });

const startSession = async (user) => {
  const session = buildSession(user);
  await logLogin(user);
  return session;
};

// Envía el código de verificación sin cortar el flujo si falla (correo caído
// o un código enviado hace menos de un minuto): el usuario puede reenviarlo.
const sendVerificationCodeQuietly = async (user, lang) => {
  try {
    await sendCode(user, CODE_PURPOSE.VERIFY_EMAIL, lang);
  } catch (error) {
    if (error?.code !== 'CODE_RECENTLY_SENT') {
      console.error('[auth] No se pudo enviar el código de verificación:', error.message);
    }
  }
};

// Mismo error para un correo que no existe y un código equivocado: no revela
// qué correos tienen cuenta.
const invalidCode = () => new AppError('El código no es correcto.', 400, 'INVALID_CODE');

export const loginUser = async ({ email, password, lang }) => {
  try {
    const user = await findUserByEmail(email);

    if (!user) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: null,
        metadata: { email, reason: 'USER_NOT_FOUND' },
      });
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    if (!user.passwordHash) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'USE_GOOGLE_SIGN_IN' },
      });
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'INVALID_PASSWORD' },
      });
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    if (!user.emailVerifiedAt) {
      await sendVerificationCodeQuietly(user, lang);
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'EMAIL_NOT_VERIFIED' },
      });
      throw new AppError(
        'Verifica tu correo: te enviamos un código.',
        403,
        'EMAIL_NOT_VERIFIED'
      );
    }

    return await startSession(user);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

export const registerUser = async ({ name, email, password, goal, lang }) => {
  try {
    const existingUser = await findUserByEmail(email);

    if (existingUser) {
      throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const newUser = await createUserWithDefaults({ name, email, passwordHash, goal });

    await logEventService({
      eventType: 'REGISTER',
      category: 'AUTH',
      userId: newUser.userId,
      metadata: { email, name },
    });

    // Si el correo falla, la cuenta queda creada: la app permite reenviarlo.
    await sendVerificationCodeQuietly({ ...newUser, name, email }, lang);

    return {
      ...newUser,
      role: 'USER',
      plan: 'FREE',
      verificationRequired: true,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

const verifiedGoogleProfile = async (idToken) => {
  const profile = await verifyGoogleIdToken(idToken);

  if (!profile.emailVerified) {
    throw new AppError('Tu correo de Google no está verificado.', 403, 'GOOGLE_EMAIL_NOT_VERIFIED');
  }

  return profile;
};

// Otra cuenta de Google con el mismo email (p. ej. borrada y recreada): no se
// sobrescribe el vínculo.
const assertNoOtherGoogleAccount = async (userId) => {
  if (await findProviderLink(userId, GOOGLE)) {
    throw new AppError(
      'Este correo ya está vinculado a otra cuenta de Google.',
      409,
      'GOOGLE_ACCOUNT_CONFLICT'
    );
  }
};

const linkGoogleToUser = async (user, { sub, email }) => {
  await linkAuthProvider({ userId: user.userId, provider: GOOGLE, providerUserId: sub, email });
  // Google demostró que el correo es suyo.
  if (!user.emailVerifiedAt) {
    await markEmailVerified(user.userId);
  }
  await logEventService({
    eventType: 'ACCOUNT_LINKED',
    category: 'AUTH',
    userId: user.userId,
    metadata: { provider: GOOGLE },
  });
};

const logGoogleLogin = (user) => logLogin(user, { method: GOOGLE });

// Busca al usuario de Google por su `sub`; si no existe, lo vincula a la
// cuenta con el mismo email o crea una nueva. `isFirstGoogleLogin` es true
// cuando esta llamada creó o vinculó la cuenta.
const resolveGoogleUser = async (profile) => {
  const { sub, email, name } = profile;

  const linkedUser = await findUserByProvider(GOOGLE, sub);
  if (linkedUser) {
    return { user: linkedUser, isFirstGoogleLogin: false };
  }

  const existingUser = await findUserByEmail(email);
  if (existingUser) {
    await assertNoOtherGoogleAccount(existingUser.userId);

    // El registro con email no verifica el correo: sin la contraseña no se
    // sabe si la cuenta es de quien entra con Google. La app la pide y vincula
    // con POST /auth/google/link.
    if (existingUser.passwordHash) {
      throw new AppError(
        'Ya tienes una cuenta con este correo. Escribe tu contraseña para vincularla con Google.',
        409,
        'GOOGLE_LINK_REQUIRES_PASSWORD'
      );
    }

    await linkGoogleToUser(existingUser, profile);
    return { user: existingUser, isFirstGoogleLogin: true };
  }

  const displayName = name?.trim() || email.split('@')[0];
  const newUser = await createUserWithDefaults({
    name: displayName,
    email,
    provider: { provider: GOOGLE, providerUserId: sub },
    // Google ya verificó el correo.
    emailVerifiedAt: new Date(),
  });

  await logEventService({
    eventType: 'REGISTER',
    category: 'AUTH',
    userId: newUser.userId,
    metadata: { email, name: displayName, method: GOOGLE },
  });

  // Se relee para tener rol, plan y edad con el mismo formato que el login.
  return { user: await findUserByProvider(GOOGLE, sub), isFirstGoogleLogin: true };
};

const toAuthError = (error) =>
  error instanceof AppError ? error : new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');

export const loginWithGoogle = async ({ idToken }) => {
  try {
    const profile = await verifiedGoogleProfile(idToken);

    let resolved;
    try {
      resolved = await resolveGoogleUser(profile);
    } catch (error) {
      // Dos primeros logins a la vez: el segundo choca con un UNIQUE y, al
      // repetir la búsqueda, encuentra lo que creó el primero.
      if (error?.code !== UNIQUE_VIOLATION) {
        throw error;
      }
      resolved = await resolveGoogleUser(profile);
    }
    const { user, isFirstGoogleLogin } = resolved;

    // Solo en el primer login con Google y si la cuenta no tiene contraseña:
    // la app le ofrece crear una para poder entrar también con email.
    const session = {
      ...buildSession(user),
      offerPasswordSetup: isFirstGoogleLogin && !user.passwordHash,
    };

    await logGoogleLogin(user);
    return session;
  } catch (error) {
    throw toAuthError(error);
  }
};

// Vincula Google a una cuenta existente cuando quien entra demuestra que es
// dueño del correo (idToken de Google) y de la cuenta (su contraseña). La
// contraseña se conserva: después puede entrar de las dos formas.
export const linkGoogleAccount = async ({ idToken, password }) => {
  try {
    const profile = await verifiedGoogleProfile(idToken);

    // Reintento de una vinculación que ya se hizo: Google basta.
    let user = await findUserByProvider(GOOGLE, profile.sub);

    if (!user) {
      user = await findUserByEmail(profile.email);
      if (!user) {
        throw new AppError('No hay ninguna cuenta con este correo.', 404, 'USER_NOT_FOUND');
      }

      await assertNoOtherGoogleAccount(user.userId);

      if (user.passwordHash && !(await bcrypt.compare(password, user.passwordHash))) {
        await logEventService({
          eventType: 'LOGIN_FAILED',
          category: 'AUTH',
          userId: user.userId,
          metadata: { email: user.email, reason: 'INVALID_PASSWORD', method: 'google-link' },
        });
        throw new AppError('Contraseña incorrecta', 401, 'INVALID_PASSWORD');
      }

      await linkGoogleToUser(user, profile);
    }

    const session = { ...buildSession(user), offerPasswordSetup: false };
    await logGoogleLogin(user);
    return session;
  } catch (error) {
    throw toAuthError(error);
  }
};

// Verifica el correo con el código y entra directo.
export const verifyEmail = async ({ email, code }) => {
  try {
    const user = await findUserByEmail(email);
    if (!user) {
      throw invalidCode();
    }

    await consumeCode(user.userId, CODE_PURPOSE.VERIFY_EMAIL, code);
    await markEmailVerified(user.userId);
    await logEventService({
      eventType: 'EMAIL_VERIFIED',
      category: 'AUTH',
      userId: user.userId,
      metadata: {},
    });

    return await startSession({ ...user, emailVerifiedAt: user.emailVerifiedAt ?? new Date() });
  } catch (error) {
    throw toAuthError(error);
  }
};

// Reenvía el código a una cuenta sin verificar. No dice si el correo existe.
export const resendVerification = async ({ email, lang }) => {
  try {
    const user = await findUserByEmail(email);
    // Al correo falso de un invitado no se escribe: rebotaría y dañaría la reputación del remitente.
    if (user && !user.emailVerifiedAt && !isGuestEmail(user.email)) {
      await sendCode(user, CODE_PURPOSE.VERIFY_EMAIL, lang);
    }
  } catch (error) {
    throw toAuthError(error);
  }
};

// Envía el código para restablecer la contraseña. No dice si el correo existe.
export const forgotPassword = async ({ email, lang }) => {
  try {
    const user = await findUserByEmail(email);
    if (user && !isGuestEmail(user.email)) {
      await sendCode(user, CODE_PURPOSE.RESET_PASSWORD, lang);
    }
  } catch (error) {
    throw toAuthError(error);
  }
};

export const resetPassword = async ({ email, code, password }) => {
  try {
    const user = await findUserByEmail(email);
    if (!user) {
      throw invalidCode();
    }

    await consumeCode(user.userId, CODE_PURPOSE.RESET_PASSWORD, code);
    await setPasswordAndVerify(user.userId, await bcrypt.hash(password, SALT_ROUNDS));
    await logEventService({
      eventType: 'PASSWORD_RESET',
      category: 'AUTH',
      userId: user.userId,
      metadata: {},
    });
  } catch (error) {
    throw toAuthError(error);
  }
};

// Cuenta de invitado de la beta: real, FREE, con datos de ejemplo y que se
// borra a las 24 h (guestCleanup.job.js).
export const loginAsGuest = async ({ lang } = {}) => {
  try {
    if (!config.guestMode.enabled) {
      throw new AppError('El modo invitado no está disponible.', 404, 'GUEST_MODE_DISABLED');
    }

    if ((await countActiveGuests()) >= config.guestMode.maxActive) {
      throw new AppError(
        'Hay demasiadas cuentas de invitado en este momento. Inténtalo más tarde o crea una cuenta.',
        503,
        'GUEST_LIMIT_REACHED'
      );
    }

    const defaults = await getDefaultRoleAndPlanIds();
    if (!defaults?.roleId || !defaults?.planId) {
      throw new AppError('Default role or plan is not configured', 500, 'AUTH_DEFAULTS_NOT_FOUND');
    }

    const email = `guest-${randomUUID()}@${GUEST_EMAIL_DOMAIN}`;
    const expiresAt = new Date(Date.now() + GUEST_TTL_MS);
    const sample = buildGuestSampleData(bogotaDayKey(), await findSampleFoodIds());

    const userId = await createGuestAccount({
      user: {
        name: GUEST_NAMES[lang] ?? GUEST_NAMES.es,
        email,
        passwordHash: null,
        goal: GUEST_PROFILE.goal,
        roleId: Number(defaults.roleId),
        planId: Number(defaults.planId),
        emailVerifiedAt: new Date(),
      },
      expiresAt,
      profile: GUEST_PROFILE,
      sample,
    });
    await createFridgeService(userId);

    await logEventService({
      eventType: 'REGISTER',
      category: 'AUTH',
      userId,
      metadata: { method: 'guest' },
    });

    // Se relee para tener rol, plan y edad con el mismo formato que el login.
    const user = await findUserByEmail(email);
    return { ...(await startSession(user)), guestExpiresAt: user.guestExpiresAt };
  } catch (error) {
    throw toAuthError(error);
  }
};
