import type { Plan, ProDuration } from '../types/admin';

/** Opciones del regalo de PRO, en el orden en que se muestran. */
export const PRO_DURATIONS: { value: ProDuration; label: string }[] = [
  { value: '7d', label: '7 días' },
  { value: '1m', label: '1 mes' },
  { value: '3m', label: '3 meses' },
  { value: '6m', label: '6 meses' },
  { value: '12m', label: '12 meses' },
  { value: 'forever', label: 'Sin vencimiento' },
];

const SPANS: Record<ProDuration, { days?: number; months?: number } | null> = {
  '7d': { days: 7 },
  '1m': { months: 1 },
  '3m': { months: 3 },
  '6m': { months: 6 },
  '12m': { months: 12 },
  forever: null,
};

function addMonths(date: Date, months: number): Date {
  const result = new Date(date);
  const day = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(day, lastDay));
  return result;
}

/**
 * Vista previa de hasta cuándo quedará PRO. Misma regla que el backend
 * (backend/src/modules/admin/proGift.js), que es quien guarda la fecha:
 * se suma a un PRO vigente con fecha, si no cuenta desde hoy.
 * null = sin vencimiento.
 */
export function previewProUntil(
  current: { plan: Plan; proUntil: string | null },
  duration: ProDuration,
  now = new Date()
): Date | null {
  const span = SPANS[duration];
  if (span === null) return null;
  if (current.plan === 'PRO' && !current.proUntil) return null;

  const currentEnd = current.proUntil ? new Date(current.proUntil) : null;
  const base = current.plan === 'PRO' && currentEnd && currentEnd > now ? currentEnd : now;
  return span.days ? new Date(base.getTime() + span.days * 86_400_000) : addMonths(base, span.months ?? 0);
}
