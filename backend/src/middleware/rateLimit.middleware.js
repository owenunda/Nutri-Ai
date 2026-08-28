import { RateLimiterRedis } from 'rate-limiter-flexible';
import { getRedisClient } from '../config/redis.client.js';
import { errorResponse } from '../utils/response.js';
import { config } from '../config/env_config.js';

const keyByUserId = (req) =>
  req.user?.userId ? `chat:user:${req.user.userId}` : `chat:ip:${req.ip}`;

const keyByIp = (req) => `ai:webhook:ip:${req.ip}`;

const keyAuthStrict = (req) => `auth:ip:${req.ip}`;
const keyGlobal = (req) =>
  req.user?.userId ? `global:user:${req.user.userId}` : `global:ip:${req.ip}`;

const buildMiddleware = ({ points, keyPrefix, keyExtractor }) => {
  const middleware = async (req, res, next) => {
    try {
      const redis = await getRedisClient();
      const rateLimiter = new RateLimiterRedis({
        storeClient: redis,
        keyPrefix,
        points,
        duration: 60,
      });
      const result = await rateLimiter.consume(keyExtractor(req), 1);

      res.setHeader('X-RateLimit-Limit', String(points));
      res.setHeader(
        'X-RateLimit-Remaining',
        String(Math.max(0, result.remainingPoints))
      );
      res.setHeader(
        'X-RateLimit-Reset',
        String(Math.ceil(result.msBeforeNext / 1000))
      );
      return next();
    } catch (err) {
      if (err?.msBeforeNext !== undefined) {
        const retryAfter = Math.ceil(err.msBeforeNext / 1000);
        res.setHeader('Retry-After', String(retryAfter));
        res.setHeader('X-RateLimit-Limit', String(points));
        res.setHeader('X-RateLimit-Remaining', '0');
        res.setHeader('X-RateLimit-Reset', String(retryAfter));
        return errorResponse(
          res,
          'Has superado el límite de solicitudes. Intenta de nuevo en unos segundos.',
          'RATE_LIMIT_EXCEEDED',
          429,
          []
        );
      }

      // Redis caído: fail-open con log. Rate limit es defensa, no ruta crítica.
      console.error('[rateLimit] Redis no disponible,允许 paso:', err.message);
      return next();
    }
  };
  middleware.points = points;
  return middleware;
};

/**
 * Rate limit para el chat con IA. Por userId si está autenticado, si no por IP.
 * Default: 10 req/min (cada request dispara 5-6 llamadas al LLM).
 */
export const chatRateLimit = buildMiddleware({
  points: config.rateLimit.chatPerMinute,
  keyPrefix: 'rl:chat',
  keyExtractor: keyByUserId,
});

/**
 * Rate limit para el webhook interno de IA (llamado por n8n).
 * Default: 60 req/min por IP.
 */
export const aiWebhookRateLimit = buildMiddleware({
  points: config.rateLimit.aiWebhookPerMinute,
  keyPrefix: 'rl:ai-webhook',
  keyExtractor: keyByIp,
});

/**
 * Rate limit estricto por IP para endpoints sensibles de auth (anti brute force).
 * Default: 5 req/min por IP.
 */
export const strictAuthRateLimit = buildMiddleware({
  points: config.rateLimit.authStrictPerMinute,
  keyPrefix: 'rl:auth',
  keyExtractor: keyAuthStrict,
});

/**
 * Rate limit global por usuario (fallback a IP) para endpoints autenticados.
 * Default: 60 req/min.
 */
export const globalRateLimit = buildMiddleware({
  points: config.rateLimit.globalPerMinute,
  keyPrefix: 'rl:global',
  keyExtractor: keyGlobal,
});