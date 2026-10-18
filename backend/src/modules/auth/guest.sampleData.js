// Perfil y datos de ejemplo de la cuenta de invitado: una semana de comidas,
// agua y peso para que el inicio y el progreso no salgan vacíos.

export const GUEST_TTL_MS = 24 * 60 * 60 * 1000;

export const GUEST_PROFILE = { age: 28, goal: 'lose', height: 170 };

const MEAL_TYPES = ['BREAKFAST', 'LUNCH', 'DINNER'];
// De hace 6 días a hoy. water_intake acepta de 1 a 4 vasos (la meta es 4).
const WATER_GLASSES = [4, 3, 4, 2, 4, 3, 1];
// Hace 6, 3 y 0 días: baja un poco, como pide el objetivo.
const WEIGHT_DAYS_AGO = [6, 3, 0];
const WEIGHTS = [72.4, 72.1, 71.8];

const shiftDay = (dayKey, days) => {
  const date = new Date(`${dayKey}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

/**
 * @param {string} todayKey Día de hoy 'YYYY-MM-DD' (hora de Bogotá).
 * @param {number[]} foodIds Alimentos del catálogo común para las comidas.
 */
export const buildGuestSampleData = (todayKey, foodIds) => {
  const days = [6, 5, 4, 3, 2, 1, 0].map((daysAgo) => shiftDay(todayKey, -daysAgo));

  return {
    physical: WEIGHT_DAYS_AGO.map((daysAgo, i) => ({
      day: shiftDay(todayKey, -daysAgo),
      height: GUEST_PROFILE.height,
      weight: WEIGHTS[i],
    })),
    water: days.map((day, i) => ({ day, glasses: WATER_GLASSES[i] })),
    meals:
      foodIds.length === 0
        ? []
        : days.map((day, d) => ({
            day,
            items: MEAL_TYPES.map((mealType, m) => ({
              mealType,
              foodId: foodIds[(d * MEAL_TYPES.length + m) % foodIds.length],
              quantity: 1,
            })),
          })),
  };
};
