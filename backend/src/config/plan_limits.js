import { config } from './env_config.js';

// Límites por plan. Las siguientes partes (recetas guardadas, progreso)
// agregan aquí los suyos. El rol ADMIN no tiene límite; eso lo decide quien
// consulta, no esta tabla.
export const CHAT_DAILY_LIMITS = Object.freeze({
  FREE: config.chatQuota.freePerDay,
  PRO: config.chatQuota.proPerDay,
});

/** Mensajes del Chef IA al día para un plan. Un plan desconocido usa FREE. */
export const chatDailyLimitFor = (plan) =>
  typeof plan === 'string' && Object.hasOwn(CHAT_DAILY_LIMITS, plan)
    ? CHAT_DAILY_LIMITS[plan]
    : CHAT_DAILY_LIMITS.FREE;
