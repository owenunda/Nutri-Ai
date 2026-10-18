import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import { computeEffectivePlan, STORE_RENEWAL_WAIT_MS } from './effectivePlan.js';
import { fetchSubscriber } from './revenuecat.client.js';
import { readStoreSubscription } from './subscriberState.js';
import {
  findExistingUserIds,
  findStoreRenewalsDue,
  inTransaction,
  lockPlanInputs,
  setEffectivePlan,
  setGift,
  upsertStoreSubscription,
} from './subscription.repository.js';

// Aplica la regla con los datos ya actualizados y guarda el plan efectivo.
const savePlan = async (client, userId, inputs, now) => {
  const effective = computeEffectivePlan(inputs, now);
  const saved = await setEffectivePlan(client, userId, effective);
  if (inputs.plan !== effective.plan) {
    console.info(`[subscription] usuario ${userId}: ${inputs.plan} -> ${effective.plan} (${effective.proSource ?? 'sin PRO'})`);
  }
  return { plan: saved.plan, proUntil: saved.proUntil, proSource: effective.proSource };
};

/**
 * Lee el estado real del usuario en RevenueCat y recalcula su plan. Se puede
 * llamar las veces que sea: el resultado depende solo de ese estado.
 */
export const syncUser = async (userId, now = new Date()) => {
  const subscriber = await fetchSubscriber(String(userId));
  const store = readStoreSubscription(subscriber, { allowSandbox: config.revenuecat.allowSandbox });

  return inTransaction(async (client) => {
    const inputs = await lockPlanInputs(client, userId);
    if (!inputs) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    await upsertStoreSubscription(client, userId, store);
    return savePlan(client, userId, { ...inputs, storeExpiresAt: store.expiresAt }, now);
  });
};

// Más que el intervalo del job (10 min): así se pregunta antes de que pase
// pro_until, cuando la cuota del Chef IA ya lo trataría como FREE.
const RENEWAL_LOOKAHEAD_MS = 15 * 60 * 1000;
const RENEWALS_PER_SWEEP = 100;
// Tantos fallos seguidos = RevenueCat caído: el resto espera al próximo barrido.
const MAX_CONSECUTIVE_FAILURES = 3;

/**
 * Le pregunta a RevenueCat por los suscriptores que iban a renovar y están por
 * perder el PRO, por si el webhook de renovación no llegó. Nunca lanza: quien
 * no se pudo confirmar sigue en PRO (expireGiftedPro no lo baja).
 * @returns {Promise<{checked: number, failed: number, stopped: boolean}>}
 */
export const renewDueStoreSubscriptions = async () => {
  const result = { checked: 0, failed: 0, stopped: false };
  let userIds;
  try {
    userIds = await findStoreRenewalsDue({
      lookaheadMs: RENEWAL_LOOKAHEAD_MS,
      waitMs: STORE_RENEWAL_WAIT_MS,
      limit: RENEWALS_PER_SWEEP,
    });
  } catch (error) {
    console.error('[subscription] no se pudieron leer las renovaciones pendientes:', error.message);
    return result;
  }

  let consecutiveFailures = 0;
  for (const userId of userIds) {
    result.checked += 1;
    try {
      await syncUser(userId);
      consecutiveFailures = 0;
    } catch (error) {
      result.failed += 1;
      consecutiveFailures += 1;
      console.error(`[subscription] no se pudo confirmar la renovación del usuario ${userId}:`, error.message);
      if (consecutiveFailures >= MAX_CONSECUTIVE_FAILURES) {
        result.stopped = true;
        break;
      }
    }
  }
  return result;
};

/**
 * Cambia el PRO regalado y recalcula el plan. giftFor recibe el estado actual
 * ({ plan, giftPro, giftProUntil, storeExpiresAt }) y devuelve el regalo nuevo.
 * @returns {Promise<Object|null>} null si el usuario no existe.
 */
export const saveGift = (userId, giftFor, now = new Date()) =>
  inTransaction(async (client) => {
    const inputs = await lockPlanInputs(client, userId);
    if (!inputs) return null;
    const gift = giftFor(inputs);
    await setGift(client, userId, gift);
    return { userId, ...(await savePlan(client, userId, { ...inputs, ...gift }, now)) };
  });

const USER_ID_PATTERN = /^\d+$/;
const MAX_INT4 = 2147483647;

const isUserId = (id) => {
  if (typeof id !== 'string' || !USER_ID_PATTERN.test(id)) return false;
  const number = Number(id);
  return number >= 1 && number <= MAX_INT4;
};

/** Usuarios de NutriLife que menciona un evento de RevenueCat. */
export const webhookUserIds = (event) => {
  const transferred = (list) => (Array.isArray(list) ? list : []);
  const ids = [event?.app_user_id, ...transferred(event?.transferred_from), ...transferred(event?.transferred_to)];
  const valid = ids.filter(isUserId).map(Number);
  return [...new Set(valid)];
};

/** El contenido del evento solo dice a quién sincronizar, nunca qué plan poner. */
export const handleWebhookEvent = async (event) => {
  if (event?.type === 'TEST') return { synced: [] };
  const candidates = webhookUserIds(event);
  if (candidates.length === 0) return { synced: [] };

  const existing = await findExistingUserIds(candidates);
  for (const userId of existing) {
    await syncUser(userId);
  }
  return { synced: existing };
};
