import { getRedisClient } from '../../config/redis.client.js';
import { chatDailyLimitFor } from '../../config/plan_limits.js';
import { AppError } from '../../utils/AppError.js';
import { bogotaDayKey, nextBogotaMidnight } from '../../utils/bogotaDay.js';
import { findUserPlanById } from './chatQuota.repository.js';

// Margen sobre la medianoche: la clave no debe expirar antes de cambiar de día.
const EXPIRY_MARGIN_SECONDS = 60 * 60;
const noop = async () => {};

const quotaKey = (userId, now) => `quota:chat:${userId}:${bogotaDayKey(now)}`;

// El plan se lee de la base de datos y no del JWT: un cambio de plan desde el
// admin aplica en el siguiente mensaje.
const resolveLimits = async (user) => {
  if (user.role === 'ADMIN') return { plan: null, unlimited: true, limit: null };
  const plan = await findUserPlanById(user.userId);
  if (!plan) throw new AppError('User not found', 401, 'UNAUTHORIZED');
  return { plan, unlimited: plan === 'PRO', limit: chatDailyLimitFor(plan) };
};

// PRO ve "ilimitado": su tope de uso justo no sale en la respuesta.
const buildQuota = ({ plan, unlimited, limit, used, now }) => ({
  plan,
  unlimited,
  limit: unlimited ? null : limit,
  used: unlimited ? null : Math.min(used, limit),
  remaining: unlimited ? null : Math.max(0, limit - used),
  resetAt: nextBogotaMidnight(now).toISOString(),
  exhausted: limit !== null && used >= limit,
});

/** Cuota de hoy sin consumir. null si Redis no responde. */
export const getChatQuota = async (user, now = new Date()) => {
  const limits = await resolveLimits(user);
  if (limits.limit === null) return buildQuota({ ...limits, used: 0, now });

  try {
    const redis = await getRedisClient();
    const used = Number(await redis.get(quotaKey(user.userId, now))) || 0;
    return buildQuota({ ...limits, used, now });
  } catch (error) {
    console.error('[chatQuota] Redis no disponible:', error.message);
    return null;
  }
};

/**
 * Descuenta un mensaje de hoy. Si ya no quedan, no descuenta y devuelve
 * allowed: false. refund() devuelve el mensaje cuando n8n falla.
 * Con Redis caído deja pasar sin contar (igual que el rate limit).
 */
export const consumeChatQuota = async (user, now = new Date()) => {
  const limits = await resolveLimits(user);
  if (limits.limit === null) {
    return { allowed: true, quota: buildQuota({ ...limits, used: 0, now }), refund: noop };
  }

  const key = quotaKey(user.userId, now);
  let redis;
  let used;
  try {
    redis = await getRedisClient();
    used = await redis.incr(key);
    if (used === 1) {
      const midnight = Math.floor(nextBogotaMidnight(now).getTime() / 1000);
      await redis.expireAt(key, midnight + EXPIRY_MARGIN_SECONDS);
    }
    if (used > limits.limit) {
      await redis.decr(key);
      return {
        allowed: false,
        quota: buildQuota({ ...limits, used: limits.limit, now }),
        refund: noop,
      };
    }
  } catch (error) {
    console.error('[chatQuota] Redis no disponible, se deja pasar:', error.message);
    return { allowed: true, quota: null, refund: noop };
  }

  const refund = async () => {
    try {
      await redis.decr(key);
    } catch (error) {
      console.error('[chatQuota] no se pudo devolver el mensaje:', error.message);
    }
  };
  return { allowed: true, quota: buildQuota({ ...limits, used, now }), refund };
};
