import { AppError } from '../../utils/AppError.js';
import {
  addWaterGlass,
  findWaterHistory,
  importWaterHistory,
  undoWaterGlass,
} from './hydration.repository.js';

export const DAILY_GOAL = 4;

const wrap = async (fn) => {
  try {
    return await fn();
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'HYDRATION_SERVICE_ERROR');
  }
};

/** Historial completo del usuario: { goal, history: { 'YYYY-MM-DD': vasos } }. */
export const getHistoryService = (userId) =>
  wrap(async () => {
    const rows = await findWaterHistory(userId);
    return {
      goal: DAILY_GOAL,
      history: Object.fromEntries(rows.map((row) => [row.day, Number(row.glasses)])),
    };
  });

export const addGlassService = (userId, date) =>
  wrap(async () => ({ date, glasses: Number(await addWaterGlass(userId, date, DAILY_GOAL)) }));

export const undoGlassService = (userId, date) =>
  wrap(async () => ({ date, glasses: Number(await undoWaterGlass(userId, date)) }));

/** El historial ya viene validado y recortado a la meta. */
export const importHistoryService = (userId, history) =>
  wrap(async () => {
    const entries = Object.entries(history).map(([day, glasses]) => ({ day, glasses }));
    if (entries.length > 0) await importWaterHistory(userId, entries);
    return { imported: entries.length };
  });
