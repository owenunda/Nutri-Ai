import { AppError } from './AppError.js';

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Fecha YYYY-MM-DD que manda la app (su día local). Sin ella se usa el día
 * UTC del servidor, que es lo que se hacía antes.
 */
export const resolveDateParam = (value) => {
  if (value === undefined || value === null || value === '') {
    return new Date().toISOString().split('T')[0];
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  if (!DATE_PATTERN.test(value) || Number.isNaN(parsed.getTime())
      || parsed.toISOString().slice(0, 10) !== value) {
    throw new AppError('La fecha debe tener el formato YYYY-MM-DD', 400, 'INVALID_DATE');
  }
  return value;
};

/** Suma días a una fecha YYYY-MM-DD. */
export const addDays = (date, days) => {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
};
