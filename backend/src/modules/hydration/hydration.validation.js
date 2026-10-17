import { AppError } from '../../utils/AppError.js';
import { DAILY_GOAL } from './hydration.service.js';

// El historial local viejo permitía 5 vasos; al importarlo se guarda como 4.
export const MAX_LEGACY_GLASSES = 5;
const MAX_IMPORT_DAYS = 1000;
const DAY_MS = 86_400_000;

const validationError = (field, message) =>
  new AppError('Validation error', 400, 'VALIDATION_ERROR', [{ field, message }]);

/** Fecha real en formato YYYY-MM-DD. */
export const isValidDay = (value) => {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const time = Date.parse(`${value}T00:00:00Z`);
  return !Number.isNaN(time) && new Date(time).toISOString().slice(0, 10) === value;
};

// Distancia en días entre `value` y el día UTC del servidor.
const daysFromServerToday = (value) => {
  const serverToday = Date.parse(`${new Date().toISOString().slice(0, 10)}T00:00:00Z`);
  return Math.round((Date.parse(`${value}T00:00:00Z`) - serverToday) / DAY_MS);
};

/** Valida { date } de sumar o deshacer un vaso. Adjunta req.hydrationDate. */
export const validateDayBody = (req, res, next) => {
  const { date } = req.body ?? {};
  // ±1 día cubre todas las zonas horarias sin dejar escribir días lejanos.
  if (!isValidDay(date) || Math.abs(daysFromServerToday(date)) > 1) {
    return next(validationError('date', 'date must be today in YYYY-MM-DD format'));
  }
  req.hydrationDate = date;
  next();
};

/** Valida { history } del import del historial local. Adjunta req.hydrationHistory. */
export const validateImportBody = (req, res, next) => {
  const { history } = req.body ?? {};
  if (!history || typeof history !== 'object' || Array.isArray(history)) {
    return next(validationError('history', 'history must be an object of date: glasses'));
  }
  const entries = Object.entries(history);
  if (entries.length > MAX_IMPORT_DAYS) {
    return next(validationError('history', 'history has too many days'));
  }
  const clean = {};
  for (const [day, glasses] of entries) {
    const validCount = Number.isInteger(glasses) && glasses >= 1 && glasses <= MAX_LEGACY_GLASSES;
    if (!isValidDay(day) || daysFromServerToday(day) > 1 || !validCount) {
      return next(validationError('history', 'history must be an object of date: glasses'));
    }
    clean[day] = Math.min(glasses, DAILY_GOAL);
  }
  req.hydrationHistory = clean;
  next();
};
