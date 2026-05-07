import { AppError } from '../../utils/AppError.js';
import {
  createPhysicalRecord,
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
