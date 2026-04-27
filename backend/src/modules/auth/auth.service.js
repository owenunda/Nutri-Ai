import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import { findUserByEmail, getAuthRepositoryStatus } from './auth.repository.js';

const JWT_EXPIRES_IN = '24h';

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
