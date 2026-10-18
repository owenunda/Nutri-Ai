// Racha de agua, con las mismas reglas que la app
// (WaterStreakRepository._currentStreak y _bestStreak). La app calcula la
// suya; esta copia es solo para el panel admin.

export const DAILY_GOAL = 4;

const DAY_MS = 24 * 60 * 60 * 1000;

/** 'YYYY-MM-DD' movido n días. */
export const addDays = (day, n) =>
  new Date(Date.parse(`${day}T00:00:00Z`) + n * DAY_MS).toISOString().slice(0, 10);

/** Fecha 'YYYY-MM-DD' de `date` en una zona horaria. */
export const dayInTimeZone = (date, timeZone) =>
  new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date);

const done = (history, day) => (history[day] ?? 0) >= DAILY_GOAL;

/** Días seguidos con la meta cumplida que terminan hoy o ayer. */
export const currentStreak = (history, today) => {
  let day = done(history, today) ? today : addDays(today, -1);
  let streak = 0;
  while (done(history, day)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
};

/** La racha más larga de toda la historia. */
export const bestStreak = (history) => {
  const completed = Object.keys(history).filter((day) => done(history, day)).sort();
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
 * Resumen del agua de un usuario.
 * El "día" lo pone la app con su fecha local, que puede ir un día por delante
 * de `today` (la fecha del panel). Si el usuario ya registró ese día, ese es
 * su hoy.
 * @param {Record<string, number>} history { 'YYYY-MM-DD': vasos }
 * @param {string} today 'YYYY-MM-DD'
 */
export const summarizeWater = (history, today) => {
  const days = Object.keys(history).sort();
  const lastDay = days.at(-1) ?? null;
  const ref = lastDay !== null && lastDay > today ? lastDay : today;

  return {
    goal: DAILY_GOAL,
    today: ref,
    glassesToday: history[ref] ?? 0,
    currentStreak: currentStreak(history, ref),
    bestStreak: bestStreak(history),
    lastSevenDays: Array.from({ length: 7 }, (_, i) => {
      const day = addDays(ref, i - 6);
      return { day, glasses: history[day] ?? 0 };
    }),
    daysLogged: days.length,
    goalDays: days.filter((day) => done(history, day)).length,
    totalGlasses: days.reduce((sum, day) => sum + history[day], 0),
    lastDay,
  };
};
