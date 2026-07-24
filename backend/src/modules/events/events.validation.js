import { AppError } from '../../utils/AppError.js';

const VALID_CATEGORIES = ['AUTH', 'AI', 'ERROR', 'CRUD', 'SYSTEM'];

const isValidDate = (value) => !Number.isNaN(Date.parse(value));

/**
 * Middleware: valida los query params de listado/stats de eventos.
 * Adjunta req.eventFilters.
 */
export const validateListEventsQuery = (req, res, next) => {
  const { type, category, userId, from, to, limit, page } = req.query;
  const details = [];

  if (category !== undefined && !VALID_CATEGORIES.includes(category)) {
    details.push({ field: 'category', message: `category must be one of: ${VALID_CATEGORIES.join(', ')}` });
  }

  const parsedUserId = userId !== undefined ? Number(userId) : null;
  if (userId !== undefined && (!Number.isInteger(parsedUserId) || parsedUserId <= 0)) {
    details.push({ field: 'userId', message: 'userId must be a positive integer' });
  }

  if (from !== undefined && !isValidDate(from)) {
    details.push({ field: 'from', message: 'from must be a valid ISO date' });
  }
  if (to !== undefined && !isValidDate(to)) {
    details.push({ field: 'to', message: 'to must be a valid ISO date' });
  }

  const parsedLimit = limit !== undefined ? Number(limit) : 50;
  if (limit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit <= 0 || parsedLimit > 500)) {
    details.push({ field: 'limit', message: 'limit must be an integer between 1 and 500' });
  }

  const parsedPage = page !== undefined ? Number(page) : 1;
  if (page !== undefined && (!Number.isInteger(parsedPage) || parsedPage <= 0)) {
    details.push({ field: 'page', message: 'page must be a positive integer' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.eventFilters = {
    type: type || undefined,
    category: category || undefined,
    userId: userId !== undefined ? parsedUserId : undefined,
    from: from || undefined,
    to: to || undefined,
    limit: parsedLimit,
    offset: (parsedPage - 1) * parsedLimit,
  };

  next();
};

/**
 * Middleware: valida el body de la política de retención (DELETE).
 * Adjunta req.retentionOptions.
 */
export const validateRetention = (req, res, next) => {
  const { days, type } = req.body ?? {};
  const details = [];

  const parsedDays = Number(days);
  if (days === undefined || !Number.isInteger(parsedDays) || parsedDays <= 0) {
    details.push({ field: 'days', message: 'days must be a positive integer' });
  }

  if (type !== undefined && (typeof type !== 'string' || type.trim() === '')) {
    details.push({ field: 'type', message: 'type must be a non-empty string' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.retentionOptions = { days: parsedDays, type: type || undefined };

  next();
};
