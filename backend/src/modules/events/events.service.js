import { AppError } from '../../utils/AppError.js';
import {
  insertEvent,
  findEvents,
  getEventStats,
  deleteEventsOlderThan,
} from './events.repository.js';

/**
 * Helper central de logging. Tolerante a fallos: NUNCA debe romper el
 * request que lo originó. Si el insert falla, solo se registra en consola.
 * @param {Object} payload  Ver insertEvent para la forma esperada.
 * @returns {Promise<Object|null>}
 */
export const logEventService = async (payload) => {
  try {
    if (!payload?.eventType || !payload?.category) {
      // No lanzamos: el logging es best-effort.
      console.error('[activity] logEventService: eventType y category son obligatorios', payload);
      return null;
    }
    return await insertEvent(payload);
  } catch (error) {
    console.error('[activity] Error registrando evento:', error.message);
    return null;
  }
};

/**
 * Lista eventos con filtros (uso admin).
 */
export const listEventsService = async (filters) => {
  try {
    return await findEvents(filters);
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'EVENTS_SERVICE_ERROR');
  }
};

/**
 * Estadísticas agregadas (uso admin).
 */
export const getStatsService = async (filters) => {
  try {
    return await getEventStats(filters);
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'EVENTS_SERVICE_ERROR');
  }
};

/**
 * Ejecuta la política de retención (uso admin).
 */
export const runRetentionService = async ({ days, type }) => {
  try {
    const deleted = await deleteEventsOlderThan(days, { type });
    return { deleted, days, type: type ?? null };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'EVENTS_SERVICE_ERROR');
  }
};
