import { AppError } from '../../utils/AppError.js';
import { USER_SORT_KEYS } from './admin.repository.js';

const VALID_PLANS = ['FREE', 'PRO'];
const VALID_ROLES = ['ADMIN', 'USER'];
const MIN_PASSWORD_LENGTH = 6;
const VALID_RANGES = [7, 14, 30, 90];

const validationError = (details) => new AppError('Validation error', 400, 'VALIDATION_ERROR', details);

const parsePositiveInt = (value) => {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
};

/** Valida ?days= del resumen. Adjunta req.overviewDays. */
export const validateOverviewQuery = (req, res, next) => {
  const { days } = req.query;
  const parsed = days === undefined ? 30 : Number(days);
  if (!VALID_RANGES.includes(parsed)) {
    return next(validationError([{ field: 'days', message: `days must be one of: ${VALID_RANGES.join(', ')}` }]));
  }
  req.overviewDays = parsed;
  next();
};

/** Valida los query params del listado de usuarios. Adjunta req.userFilters. */
export const validateListUsersQuery = (req, res, next) => {
  const { search, plan, sort, page, limit } = req.query;
  const details = [];

  if (plan !== undefined && plan !== '' && !VALID_PLANS.includes(plan)) {
    details.push({ field: 'plan', message: `plan must be one of: ${VALID_PLANS.join(', ')}` });
  }
  if (sort !== undefined && !USER_SORT_KEYS.includes(sort)) {
    details.push({ field: 'sort', message: `sort must be one of: ${USER_SORT_KEYS.join(', ')}` });
  }

  const parsedLimit = limit === undefined ? 25 : parsePositiveInt(limit);
  if (parsedLimit === null || parsedLimit > 200) {
    details.push({ field: 'limit', message: 'limit must be an integer between 1 and 200' });
  }
  const parsedPage = page === undefined ? 1 : parsePositiveInt(page);
  if (parsedPage === null) {
    details.push({ field: 'page', message: 'page must be a positive integer' });
  }

  if (details.length > 0) return next(validationError(details));

  req.userFilters = {
    search: typeof search === 'string' && search.trim() ? search.trim() : undefined,
    plan: plan || undefined,
    sort: sort || 'recent',
    limit: parsedLimit,
    offset: (parsedPage - 1) * parsedLimit,
  };
  next();
};

/** Valida :userId. Adjunta req.targetUserId. */
export const validateUserIdParam = (req, res, next) => {
  const userId = parsePositiveInt(req.params.userId);
  if (userId === null) {
    return next(validationError([{ field: 'userId', message: 'userId must be a positive integer' }]));
  }
  req.targetUserId = userId;
  next();
};

/** Valida el body del cambio de plan. */
export const validatePlanBody = (req, res, next) => {
  const { plan } = req.body ?? {};
  if (!VALID_PLANS.includes(plan)) {
    return next(validationError([{ field: 'plan', message: `plan must be one of: ${VALID_PLANS.join(', ')}` }]));
  }
  next();
};

/** Valida el body del cambio de contraseña (mismo mínimo que el registro). */
export const validatePasswordBody = (req, res, next) => {
  const { password } = req.body ?? {};
  if (typeof password !== 'string' || password.length < MIN_PASSWORD_LENGTH) {
    return next(
      validationError([
        { field: 'password', message: `password must be at least ${MIN_PASSWORD_LENGTH} characters` },
      ])
    );
  }
  next();
};

/** Valida el body del cambio de rol. */
export const validateRoleBody = (req, res, next) => {
  const { role } = req.body ?? {};
  if (!VALID_ROLES.includes(role)) {
    return next(validationError([{ field: 'role', message: `role must be one of: ${VALID_ROLES.join(', ')}` }]));
  }
  next();
};
