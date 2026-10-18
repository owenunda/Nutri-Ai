import { renewDueStoreSubscriptions } from '../subscription/subscription.service.js';
import { expireGiftedPro } from './admin.repository.js';

// Cada cuánto se pasa a FREE a quien tenía PRO regalado y ya venció. La cuota
// del chat revisa la fecha al momento, así que este barrido solo pone al día
// el plan para el resto (perfil, anuncios, panel).
const INTERVAL_MS = 10 * 60 * 1000;

// Antes de vencer, pregunta a RevenueCat por quien iba a renovar, por si no
// llegó el webhook. Un fallo ahí nunca impide vencer al resto.
const checkRenewals = async (renew) => {
  try {
    const { checked, failed, stopped } = await renew();
    if (checked > 0) {
      console.info(`[proExpiry] renovaciones revisadas: ${checked}, sin confirmar: ${failed}${stopped ? ' (RevenueCat no responde)' : ''}`);
    }
  } catch (error) {
    console.error('[proExpiry] no se pudieron revisar las renovaciones:', error.message);
  }
};

/** Un barrido. Nunca lanza: un fallo de la base solo se registra. */
export const runProExpiry = async (expire = expireGiftedPro, renew = renewDueStoreSubscriptions) => {
  await checkRenewals(renew);
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
