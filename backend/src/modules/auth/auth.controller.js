import { successResponse } from '../../utils/response.js';
import { getAuthModuleStatus } from './auth.service.js';

export const getAuthHealth = async (req, res, next) => {
  try {
    const status = await getAuthModuleStatus();
    return successResponse(res, status, 'Auth module is running', 200);
  } catch (error) {
    next(error);
  }
};
