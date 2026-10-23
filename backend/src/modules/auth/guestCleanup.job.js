import { findExpiredGuestIds } from './guest.repository.js';
import { deleteUserAccountData } from '../user/user.repository.js';
import { runRetentionService } from '../events/events.service.js';

// Cada cuánto se borran los invitados vencidos. Su token ya no sirve desde
// que vencen, así que esto solo limpia la base.
const INTERVAL_MS = 60 * 60 * 1000;
let lastRetentionRunDay = null;

/** Un barrido. Nunca lanza: un fallo solo se registra y el resto sigue. */
export const runGuestCleanup = async (
  findExpired = findExpiredGuestIds,
  deleteAccount = deleteUserAccountData
) => {
  let userIds;
  try {
    userIds = await findExpired();
  } catch (error) {
    console.error('[guestCleanup] no se pudieron buscar los invitados vencidos:', error?.message ?? error);
    return [];
  }

  const deleted = [];
  for (const userId of userIds) {
    try {
      if (await deleteAccount(userId)) deleted.push(userId);
    } catch (error) {
      console.error(`[guestCleanup] no se pudo borrar al invitado ${userId}:`, error?.message ?? error);
    }
  }

  if (deleted.length > 0) {
    console.info(`[guestCleanup] ${deleted.length} invitado(s) borrado(s):`, deleted.join(', '));
  }
  return deleted;
};

/** Ejecuta la retención de eventos una vez por día UTC; si falla, reintenta en el siguiente ciclo. */
export const runDailyRetention = async (now = new Date()) => {
  const runDay = now.toISOString().slice(0, 10);
  if (lastRetentionRunDay === runDay) return null;

  // Marcar antes de esperar evita que dos ciclos solapados lancen la misma limpieza.
  lastRetentionRunDay = runDay;
  try {
    const result = await runRetentionService({ days: 90 });
    if (result?.deleted > 0) {
      console.info(`[guestCleanup] ${result.deleted} evento(s) de más de 90 días eliminados`);
    }
    return result;
  } catch (error) {
    // Si la base falla, el job horario podrá intentarlo otra vez ese mismo día.
    if (lastRetentionRunDay === runDay) lastRetentionRunDay = null;
    console.error('[guestCleanup] no se pudieron eliminar los eventos antiguos:', error?.message ?? error);
    return null;
  }
};

export const runGuestCleanupJob = async (now = new Date()) => {
  await runGuestCleanup();
  await runDailyRetention(now);
};

/** Barre al arrancar y después cada hora. */
export const startGuestCleanupJob = () => {
  runGuestCleanupJob();
  const timer = setInterval(runGuestCleanupJob, INTERVAL_MS);
  timer.unref?.();
  return timer;
};
