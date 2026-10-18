import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';
import { computeEffectivePlan } from './effectivePlan.js';
import { fetchSubscriber } from './revenuecat.client.js';
import { readStoreSubscription } from './subscriberState.js';
import {
  findExistingUserIds,
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

/** Usuarios de NutriLife que menciona un evento de RevenueCat. */
export const webhookUserIds = (event) => {
  const ids = [event?.app_user_id, ...(event?.transferred_from ?? []), ...(event?.transferred_to ?? [])];
  const valid = ids.filter((id) => typeof id === 'string' && USER_ID_PATTERN.test(id)).map(Number);
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
