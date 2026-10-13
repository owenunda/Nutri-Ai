import { AppError } from '../../utils/AppError.js';
import { EVENT_MODULES } from './events.repository.js';

const VALID_CATEGORIES = ['AUTH', 'AI', 'ERROR', 'CRUD', 'SYSTEM'];

const isValidDate = (value) => !Number.isNaN(Date.parse(value));

const BOOLEAN_VALUES = ['true', 'false', '1', '0'];
const parseBoolean = (value) => value === 'true' || value === '1';

/**
 * Middleware: valida los query params de listado/stats de eventos.
 * Adjunta req.eventFilters.
 */
export const validateListEventsQuery = (req, res, next) => {
  const { type, category, module, userId, from, to, limit, page, hideReads, hideBots } = req.query;
  const details = [];

  if (category !== undefined && !VALID_CATEGORIES.includes(category)) {
    details.push({ field: 'category', message: `category must be one of: ${VALID_CATEGORIES.join(', ')}` });
  }

  if (module !== undefined && !EVENT_MODULES.includes(module)) {
    details.push({ field: 'module', message: `module must be one of: ${EVENT_MODULES.join(', ')}` });
  }

  for (const [field, value] of [['hideReads', hideReads], ['hideBots', hideBots]]) {
    if (value !== undefined && !BOOLEAN_VALUES.includes(value)) {
      details.push({ field, message: `${field} must be true or false` });
    }
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
    module: module || undefined,
    hideReads: hideReads !== undefined && parseBoolean(hideReads),
    hideBots: hideBots !== undefined && parseBoolean(hideBots),
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
