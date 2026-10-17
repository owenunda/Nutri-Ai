// Bogotá está en UTC-5 todo el año (no tiene horario de verano): basta un
// desplazamiento fijo para saber en qué día va el usuario.
const BOGOTA_OFFSET_MS = 5 * 60 * 60 * 1000;

const toBogota = (now) => new Date(now.getTime() - BOGOTA_OFFSET_MS);

/** Día en Bogotá como 'YYYY-MM-DD'. */
export const bogotaDayKey = (now = new Date()) => toBogota(now).toISOString().slice(0, 10);

/** Instante (UTC) de la próxima medianoche de Bogotá. */
export const nextBogotaMidnight = (now = new Date()) => {
  const local = toBogota(now);
  local.setUTCHours(24, 0, 0, 0);
  return new Date(local.getTime() + BOGOTA_OFFSET_MS);
};
