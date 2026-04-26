import { AppError } from '../../utils/AppError.js';
import { getAuthRepositoryStatus } from './auth.repository.js';

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
