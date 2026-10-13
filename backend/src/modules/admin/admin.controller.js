import {
  getOverviewService,
  listUsersService,
  getUserDetailService,
  updateUserPlanService,
} from './admin.service.js';
import { successResponse } from '../../utils/response.js';

export const getOverview = async (req, res, next) => {
  try {
    const overview = await getOverviewService(req.overviewDays);
    return successResponse(res, overview, 'Resumen consultado con éxito');
  } catch (error) {
    next(error);
  }
};

export const listUsers = async (req, res, next) => {
  try {
    const result = await listUsersService(req.userFilters);
    return successResponse(res, result, 'Usuarios consultados con éxito');
  } catch (error) {
    next(error);
  }
};

export const getUserDetail = async (req, res, next) => {
  try {
    const detail = await getUserDetailService(req.targetUserId);
    return successResponse(res, detail, 'Usuario consultado con éxito');
  } catch (error) {
    next(error);
  }
};

export const updateUserPlan = async (req, res, next) => {
  try {
    const result = await updateUserPlanService(req.targetUserId, req.body.plan);
    return successResponse(res, result, 'Plan actualizado con éxito');
  } catch (error) {
    next(error);
  }
};
