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
  linkProviderToExistingUser,
} from './auth.repository.js';
import { verifyGoogleIdToken } from './google.verifier.js';
import { createFridgeService } from '../fridge/fridge.service.js';
import { logEventService } from '../events/events.service.js';

const JWT_EXPIRES_IN = '1h';
const SALT_ROUNDS = 10;
const GOOGLE = 'google';
const UNIQUE_VIOLATION = '23505';

export const getAuthModuleStatus = async () => {
  try {
    const repository = await getAuthRepositoryStatus();

    return {
      module: 'auth',
      status: 'running',
      repository,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

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
  };

  return jwt.sign(tokenPayload, config.jwt.secret, { expiresIn: JWT_EXPIRES_IN });
};

// Respuesta común de los logins. Sin edad, el usuario no terminó el setup
// del perfil y la app lo manda ahí en vez de al Dashboard.
const buildSession = (user) => {
  const { passwordHash, ...safeUser } = user;

  return {
    token: issueToken(user),
    user: safeUser,
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
  };

  const newUser = provider
    ? await createUserWithProvider({ ...userData, ...provider })
    : await createUser(userData);

  await createFridgeService(newUser.userId);

  return newUser;
};

export const loginUser = async ({ email, password }) => {
  try {
    const user = await findUserByEmail(email);

    if (!user) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: null,
        metadata: { email, reason: 'USER_NOT_FOUND' },
      });
      throw new AppError('Cuenta no existe', 404, 'USER_NOT_FOUND');
    }

    if (!user.passwordHash) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'USE_GOOGLE_SIGN_IN' },
      });
      throw new AppError(
        'Esta cuenta usa Google. Toca «Continuar con Google».',
        409,
        'USE_GOOGLE_SIGN_IN'
      );
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      await logEventService({
        eventType: 'LOGIN_FAILED',
        category: 'AUTH',
        userId: user.userId,
        metadata: { email, reason: 'INVALID_PASSWORD' },
      });
      throw new AppError('Contraseña incorrecta', 401, 'INVALID_PASSWORD');
    }

    const session = buildSession(user);

    await logEventService({
      eventType: 'LOGIN',
      category: 'AUTH',
      userId: user.userId,
      metadata: { email: user.email, role: user.role },
    });

    return session;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

export const registerUser = async ({ name, email, password, goal }) => {
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

    return {
      ...newUser,
      role: 'USER',
      plan: 'FREE',
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};

// Busca al usuario de Google por su `sub`; si no existe, lo vincula a la
// cuenta con el mismo email o crea una nueva.
const resolveGoogleUser = async ({ sub, email, name }) => {
  const linkedUser = await findUserByProvider(GOOGLE, sub);
  if (linkedUser) {
    return linkedUser;
  }

  const existingUser = await findUserByEmail(email);
  if (existingUser) {
    // Otra cuenta de Google con el mismo email (p. ej. borrada y recreada):
    // no se sobrescribe el vínculo.
    if (await findProviderLink(existingUser.userId, GOOGLE)) {
      throw new AppError(
        'Este correo ya está vinculado a otra cuenta de Google.',
        409,
        'GOOGLE_ACCOUNT_CONFLICT'
      );
    }

    // Los ADMIN conservan la contraseña: el panel de admin solo entra con
    // ella, y como el rol se asigna a mano no pueden ser una cuenta que otra
    // persona registró con su correo.
    const clearPassword = existingUser.role !== 'ADMIN';
    await linkProviderToExistingUser({
      userId: existingUser.userId,
      provider: GOOGLE,
      providerUserId: sub,
      email,
      clearPassword,
    });
    await logEventService({
      eventType: 'ACCOUNT_LINKED',
      category: 'AUTH',
      userId: existingUser.userId,
      metadata: { provider: GOOGLE },
    });
    return clearPassword ? { ...existingUser, passwordHash: null } : existingUser;
  }

  const displayName = name?.trim() || email.split('@')[0];
  const newUser = await createUserWithDefaults({
    name: displayName,
    email,
    provider: { provider: GOOGLE, providerUserId: sub },
  });

  await logEventService({
    eventType: 'REGISTER',
    category: 'AUTH',
    userId: newUser.userId,
    metadata: { email, name: displayName, method: GOOGLE },
  });

  // Se relee para tener rol, plan y edad con el mismo formato que el login.
  return findUserByProvider(GOOGLE, sub);
};

export const loginWithGoogle = async ({ idToken }) => {
  try {
    const profile = await verifyGoogleIdToken(idToken);

    if (!profile.emailVerified) {
      throw new AppError('Tu correo de Google no está verificado.', 403, 'GOOGLE_EMAIL_NOT_VERIFIED');
    }

    let user;
    try {
      user = await resolveGoogleUser(profile);
    } catch (error) {
      // Dos primeros logins a la vez: el segundo choca con un UNIQUE y, al
      // repetir la búsqueda, encuentra lo que creó el primero.
      if (error?.code !== UNIQUE_VIOLATION) {
        throw error;
      }
      user = await resolveGoogleUser(profile);
    }

    const session = buildSession(user);

    await logEventService({
      eventType: 'LOGIN',
      category: 'AUTH',
      userId: user.userId,
      metadata: { email: user.email, role: user.role, method: GOOGLE },
    });

    return session;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'AUTH_SERVICE_ERROR');
  }
};
