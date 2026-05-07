import { successResponse } from '../../utils/response.js';
import { getUserProfile, savePhysicalRecord } from './user.service.js';

export const getProfile = async (req, res, next) => {
  try {
    const profile = await getUserProfile(req.user.userId);
    return successResponse(res, profile, 'User profile retrieved successfully', 200);
  } catch (error) {
    next(error);
  }
};

export const createPhysical = async (req, res, next) => {
  try {
    const physicalRecord = await savePhysicalRecord(req.user.userId, req.physicalRecordData);
    return successResponse(res, physicalRecord, 'Physical record created successfully', 201);
  } catch (error) {
    next(error);
  }
};
