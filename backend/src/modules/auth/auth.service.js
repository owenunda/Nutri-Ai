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

const JWT_EXPIRES_IN = '24h';
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
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    if (!config.jwt.secret) {
      throw new AppError('JWT secret is not configured', 500, 'AUTH_CONFIG_ERROR');
    }

    const tokenPayload = {
      userId: user.userId,
      email: user.email,
      role: user.role,
      plan: user.plan,
    };

    const token = jwt.sign(tokenPayload, config.jwt.secret, {
      expiresIn: JWT_EXPIRES_IN,
    });

    const { passwordHash, ...safeUser } = user;

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
