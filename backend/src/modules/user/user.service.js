import { AppError } from '../../utils/AppError.js';
import { findUserProfileById } from './user.repository.js';

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
