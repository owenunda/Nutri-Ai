import { AppError } from '../../utils/AppError.js';
import {
  getOverview,
  findUsers,
  findUserDetail,
  updateUserPlan,
} from './admin.repository.js';

const wrap = async (fn) => {
  try {
    return await fn();
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'ADMIN_SERVICE_ERROR');
  }
};

/** Resumen general del panel admin. */
export const getOverviewService = (days) => wrap(() => getOverview(days));

/** Lista paginada de usuarios con su uso. */
export const listUsersService = (filters) => wrap(() => findUsers(filters));

/** Detalle de un usuario. */
export const getUserDetailService = (userId) =>
  wrap(async () => {
    const detail = await findUserDetail(userId);
    if (!detail) throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    return detail;
  });

/** Cambia el plan de un usuario (FREE / PRO). */
export const updateUserPlanService = (userId, plan) =>
  wrap(async () => {
    const updated = await updateUserPlan(userId, plan);
    if (!updated) throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    return updated;
  });
