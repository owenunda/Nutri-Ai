import bcrypt from 'bcrypt';
import { AppError } from '../../utils/AppError.js';
import { logEventService } from '../events/events.service.js';
import {
  getOverview,
  findUsers,
  findUserDetail,
  updateUserPassword,
  updateUserPlan,
  updateUserRole,
} from './admin.repository.js';

const SALT_ROUNDS = 10;

const userNotFound = () => new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');

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

/** Pone una contraseña nueva a un usuario. Si solo entraba con Google, pasa a tener ambos. */
export const updateUserPasswordService = (adminId, userId, password) =>
  wrap(async () => {
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const updated = await updateUserPassword(userId, passwordHash);
    if (!updated) throw userNotFound();

    await logEventService({
      eventType: 'PASSWORD_RESET_BY_ADMIN',
      category: 'AUTH',
      userId,
      metadata: { by: adminId },
    });
    return updated;
  });

/**
 * Da o quita el rol ADMIN. Un admin no puede quitárselo a sí mismo, para no
 * quedarse fuera del panel por error. El rol va en el JWT: el cambio se nota
 * en el próximo inicio de sesión de ese usuario.
 */
export const updateUserRoleService = (adminId, userId, role) =>
  wrap(async () => {
    if (adminId === userId && role !== 'ADMIN') {
      throw new AppError('No puedes quitarte el rol de administrador a ti mismo', 409, 'CANNOT_DEMOTE_SELF');
    }

    const updated = await updateUserRole(userId, role);
    if (!updated) throw userNotFound();

    await logEventService({
      eventType: 'ROLE_CHANGED',
      category: 'AUTH',
      userId,
      metadata: { role, by: adminId },
    });
    return updated;
  });
