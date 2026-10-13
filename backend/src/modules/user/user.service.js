import bcrypt from 'bcrypt';
import { AppError } from '../../utils/AppError.js';
import { logEventService } from '../events/events.service.js';
import {
  createPhysicalRecord,
  deleteUserAccountData,
  findUserPasswordHashById,
  findPhysicalHistoryByUserId,
  findUserProfileById,
  updateUserProfileData,
} from './user.repository.js';

export const getUserProfile = async (userId) => {
  try {
    const user = await findUserProfileById(userId);

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return user;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const savePhysicalRecord = async (userId, physicalData) => {
  try {
    const physicalRecord = await createPhysicalRecord(userId, physicalData);

    if (!physicalRecord) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return physicalRecord;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const getPhysicalHistory = async (userId) => {
  try {
    const user = await findUserProfileById(userId);

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return await findPhysicalHistoryByUserId(userId);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const updateUserProfile = async (userId, profileData) => {
  try {
    const updatedUser = await updateUserProfileData(userId, profileData);

    if (!updatedUser) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return updatedUser;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

// Se pide la contraseña aunque el token sea válido: un teléfono desbloqueado
// en manos de otro no debería bastar para borrar la cuenta.
export const deleteUserAccount = async (userId, password) => {
  try {
    const passwordHash = await findUserPasswordHashById(userId);

    if (!passwordHash) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const isPasswordValid = await bcrypt.compare(password, passwordHash);

    // 403 y no 401: el token es válido, y la app cierra sesión ante un 401.
    if (!isPasswordValid) {
      throw new AppError('Contraseña incorrecta', 403, 'INVALID_PASSWORD');
    }

    const deleted = await deleteUserAccountData(userId);

    if (!deleted) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    // Sin userId ni correo: el evento solo cuenta que hubo un borrado.
    await logEventService({
      eventType: 'ACCOUNT_DELETED',
      category: 'AUTH',
      userId: null,
      metadata: {},
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};
