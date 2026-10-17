import { expireGiftedPro } from './admin.repository.js';

// Cada cuánto se pasa a FREE a quien tenía PRO regalado y ya venció. La cuota
// del chat revisa la fecha al momento, así que este barrido solo pone al día
// el plan para el resto (perfil, anuncios, panel).
const INTERVAL_MS = 10 * 60 * 1000;

/** Un barrido. Nunca lanza: un fallo de la base solo se registra. */
export const runProExpiry = async (expire = expireGiftedPro) => {
  try {
    const userIds = await expire();
    if (userIds.length > 0) {
      console.info(`[proExpiry] ${userIds.length} usuario(s) volvieron a FREE:`, userIds.join(', '));
    }
    return userIds;
  } catch (error) {
    console.error('[proExpiry] no se pudo revisar el PRO vencido:', error.message);
    return [];
  }
};

/** Barre al arrancar y después cada 10 minutos. */
export const startProExpiryJob = () => {
  runProExpiry();
  const timer = setInterval(runProExpiry, INTERVAL_MS);
  timer.unref?.();
  return timer;
};
