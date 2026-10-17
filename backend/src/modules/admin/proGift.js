// Duraciones del PRO regalado desde el panel admin. null = sin vencimiento.
export const PRO_DURATIONS = Object.freeze({
  '7d': { days: 7 },
  '1m': { months: 1 },
  '3m': { months: 3 },
  '6m': { months: 6 },
  '12m': { months: 12 },
  forever: null,
});

// Suma meses sin desbordar: del 31 de enero, 1 mes es el último día de febrero.
const addMonths = (date, months) => {
  const result = new Date(date);
  const day = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(day, lastDay));
  return result;
};

/**
 * Hasta cuándo queda PRO un usuario al regalarle `duration`.
 * Si ya tenía PRO vigente con fecha, el regalo se suma a esa fecha; si no,
 * cuenta desde `now`. Un PRO sin vencimiento lo conserva.
 * @returns {Date|null} null = sin vencimiento.
 */
export const computeProUntil = (current, duration, now = new Date()) => {
  const span = PRO_DURATIONS[duration];
  if (span === null) return null;
  if (current.plan === 'PRO' && !current.proUntil) return null;

  const currentEnd = current.proUntil ? new Date(current.proUntil) : null;
  const base = current.plan === 'PRO' && currentEnd > now ? currentEnd : now;
  return span.days
    ? new Date(base.getTime() + span.days * 24 * 60 * 60 * 1000)
    : addMonths(base, span.months);
};
