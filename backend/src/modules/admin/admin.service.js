import bcrypt from 'bcrypt';
import { AppError } from '../../utils/AppError.js';
import { logEventService } from '../events/events.service.js';
import { deleteUserAccountData } from '../user/user.repository.js';
import {
  getOverview,
  findUsers,
  findUserDetail,
  findUserPlanState,
  updateUserPassword,
  updateUserPlan,
  updateUserRole,
} from './admin.repository.js';
import { computeProUntil } from './proGift.js';

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

/**
 * Cambia el plan de un usuario. PRO lleva la duración del regalo (ver
 * proGift.js); FREE borra la fecha de vencimiento.
 */
export const updateUserPlanService = (userId, plan, duration, now = new Date()) =>
  wrap(async () => {
    const current = await findUserPlanState(userId);
    if (!current) throw userNotFound();
    const proUntil = plan === 'PRO' ? computeProUntil(current, duration, now) : null;
    const updated = await updateUserPlan(userId, plan, proUntil);
    if (!updated) throw userNotFound();
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

/**
 * Borra la cuenta de un usuario y todos sus datos, con la misma transacción
 * que usa la app. Un admin no puede borrar la suya desde el panel.
 */
export const deleteUserService = (adminId, userId) =>
  wrap(async () => {
    if (adminId === userId) {
      throw new AppError('No puedes eliminar tu propia cuenta desde el panel', 409, 'CANNOT_DELETE_SELF');
    }

    const deleted = await deleteUserAccountData(userId);
    if (!deleted) throw userNotFound();

    // Sin userId ni correo, como el borrado desde la app: solo consta quién lo hizo.
    await logEventService({
      eventType: 'ACCOUNT_DELETED',
      category: 'AUTH',
      userId: null,
      metadata: { by: adminId },
    });
  });
