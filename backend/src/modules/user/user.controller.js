import { successResponse } from '../../utils/response.js';
import { getUserProfile, updateUserProfile } from './user.service.js';

export const getProfile = async (req, res, next) => {
  try {
    const profile = await getUserProfile(req.user.userId);
    return successResponse(res, profile, 'User profile retrieved successfully', 200);
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const updatedProfile = await updateUserProfile(req.user.userId, req.profileUpdateData);
    return successResponse(res, updatedProfile, 'User profile updated successfully', 200);
  } catch (error) {
    next(error);
  }
};
