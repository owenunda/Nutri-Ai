import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import {
  createUser,
  findUserByEmail,
  getAuthRepositoryStatus,
  getDefaultRoleAndPlanIds,
} from './auth.repository.js';
import { createFridgeService } from '../fridge/fridge.service.js'; // línea nueva
import { logEventService } from '../events/events.service.js';


const JWT_EXPIRES_IN = '1h';
const SALT_ROUNDS = 10;

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

    if (!config.jwt.secret) {
      throw new AppError('JWT secret is not configured', 500, 'AUTH_CONFIG_ERROR');
    }

    const tokenPayload = {
      userId: user.userId,
      email: user.email,
      role: user.role,
      plan: user.plan,
      name: user.name,
      goal: user.goal
    };

    const token = jwt.sign(tokenPayload, config.jwt.secret, {
      expiresIn: JWT_EXPIRES_IN,
    });

    const { passwordHash, ...safeUser } = user;

    await logEventService({
      eventType: 'LOGIN',
      category: 'AUTH',
      userId: user.userId,
      metadata: { email: user.email, role: user.role },
    });

    return {
      token,
      user: safeUser,
    };
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

    const defaults = await getDefaultRoleAndPlanIds();

    if (!defaults?.roleId || !defaults?.planId) {
      throw new AppError(
        'Default role or plan is not configured',
        500,
        'AUTH_DEFAULTS_NOT_FOUND'
      );
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const newUser = await createUser({
      name,
      email,
      passwordHash,
      goal,
      roleId: Number(defaults.roleId),
      planId: Number(defaults.planId),
    });

    // Crea automáticamente la nevera del usuario recién registrado
    await createFridgeService(newUser.userId); // 👈 aquí

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
