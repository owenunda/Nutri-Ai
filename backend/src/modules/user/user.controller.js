import { successResponse } from '../../utils/response.js';
import { getUserProfile } from './user.service.js';

export const getProfile = async (req, res, next) => {
  try {
    const profile = await getUserProfile(req.user.userId);
    return successResponse(res, profile, 'User profile retrieved successfully', 200);
  } catch (error) {
    next(error);
  }
};
