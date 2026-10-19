// Racha del objetivo calórico. Un día cuenta si lo comido cae dentro del
// rango de la meta según el objetivo: bajar es no pasarse sin quedarse muy
// corto; subir es llegar a la meta sin pasarse demasiado.
import { addDays } from '../../utils/date.js';

// Fracciones de la meta diaria que valen como día cumplido.
const RANGES = {
  lose: { min: 0.7, max: 1.0 },
  maintain: { min: 0.85, max: 1.15 },
  gain: { min: 1.0, max: 1.3 },
};

/** 'lose', 'gain' o 'maintain' a partir del objetivo del perfil (es o en). */
export const goalKind = (goal) => {
  const normalized = goal?.toLowerCase() ?? '';
  if (['perder', 'bajar', 'lose'].some((word) => normalized.includes(word))) return 'lose';
  if (['ganar', 'subir', 'gain'].some((word) => normalized.includes(word))) return 'gain';
  return 'maintain';
};

/** Kcal mínimas y máximas de un día cumplido. */
export const calorieRange = (kind, dailyLimit) => {
  const { min, max } = RANGES[kind] ?? RANGES.maintain;
  return { min: Math.round(dailyLimit * min), max: Math.round(dailyLimit * max) };
};

export const isGoalDay = (calories, { min, max }) => calories > 0 && calories >= min && calories <= max;

const done = (history, day, range) => isGoalDay(history[day] ?? 0, range);

/**
 * Días seguidos cumplidos que terminan hoy o ayer. Hoy sigue en curso: si
 * todavía no llega al mínimo cuenta desde ayer, pero si ya se pasó del
 * máximo la racha se cortó.
 * @param {Record<string, number>} history { 'YYYY-MM-DD': kcal }
 */
export const currentCalorieStreak = (history, today, range) => {
  if ((history[today] ?? 0) > range.max) return 0;
  let day = done(history, today, range) ? today : addDays(today, -1);
  let streak = 0;
  while (done(history, day, range)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
};

/** La racha más larga de toda la historia. */
export const bestCalorieStreak = (history, range) => {
  const completed = Object.keys(history).filter((day) => done(history, day, range)).sort();
  let best = 0;
  let current = 0;
  let previous = null;
  for (const day of completed) {
    current = previous !== null && day === addDays(previous, 1) ? current + 1 : 1;
    best = Math.max(best, current);
    previous = day;
  }
  return best;
};

/**
 * Resumen de calorías de un usuario para el panel admin.
 * El "día" lo pone la app con su fecha local, que puede ir un día por delante
 * de `today` (la fecha del panel). Si ya registró ese día, ese es su hoy.
 * @param {Record<string, number>} history { 'YYYY-MM-DD': kcal }
 * @param {string} today 'YYYY-MM-DD'
 */
export const summarizeCalories = (history, today, range) => {
  const days = Object.keys(history).filter((day) => history[day] > 0).sort();
  const lastDay = days.at(-1) ?? null;
  const ref = lastDay !== null && lastDay > today ? lastDay : today;

  return {
    today: ref,
    caloriesToday: history[ref] ?? 0,
    currentStreak: currentCalorieStreak(history, ref, range),
    bestStreak: bestCalorieStreak(history, range),
    daysLogged: days.length,
    goalDays: days.filter((day) => isGoalDay(history[day], range)).length,
    lastSevenDays: Array.from({ length: 7 }, (_, i) => {
      const day = addDays(ref, i - 6);
      return { day, calories: history[day] ?? 0 };
    }),
  };
};
