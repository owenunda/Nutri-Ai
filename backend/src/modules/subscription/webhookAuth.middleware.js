import { timingSafeEqual } from 'node:crypto';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const sameSecret = (received, expected) => {
  const a = Buffer.from(received ?? '');
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
};

/** RevenueCat manda en Authorization el valor configurado en su dashboard. */
export const verifyWebhookAuth = (req, res, next) => {
  const expected = config.revenuecat.webhookAuth;
  if (!expected || !sameSecret(req.get('authorization'), expected)) {
    return next(new AppError('Invalid token', 401, 'UNAUTHORIZED', ['Invalid token']));
  }
  return next();
};
