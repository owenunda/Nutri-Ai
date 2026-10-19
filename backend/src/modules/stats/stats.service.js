import {
  getUserNutritionalData,
  getConsumptionCaloriesByDate,
  getDailyConsumptionRepository,
  getFirstMealDateRepository,
} from './stats.repository.js';
import { AppError } from '../../utils/AppError.js';
import { resolveDateParam, addDays } from '../../utils/date.js';
import {
  bestCalorieStreak,
  calorieRange,
  currentCalorieStreak,
  goalKind,
  isGoalDay,
} from './calorieStreak.js';

const ACTIVITY_FACTOR = 1.2;
const MAX_WEIGHT_LOSS_DEFICIT = 500;
const WEIGHT_LOSS_DEFICIT_RATIO = 0.15;
const MIN_WEIGHT_LOSS_CALORIES = 1200;
const MIN_SAFE_DAILY_CALORIES = 1200;

/** Meta diaria en kcal, o null si faltan edad, altura o peso. */
export const calculateDailyLimit = ({ age, goal, height, weight }) => {
  if (!age || !height || !weight) return null;
  const parsedHeight = parseFloat(height);
  const heightInCentimeters = parsedHeight <= 3 ? parsedHeight * 100 : parsedHeight;
  const bmr = (10 * parseFloat(weight)) + (6.25 * heightInCentimeters) - (5 * parseInt(age)) - 80;
  const maintenanceCalories = bmr * ACTIVITY_FACTOR;

  let dailyLimit = maintenanceCalories;
  const kind = goalKind(goal);

  if (kind === 'lose') {
    const deficit = Math.min(
      MAX_WEIGHT_LOSS_DEFICIT,
      maintenanceCalories * WEIGHT_LOSS_DEFICIT_RATIO
    );
    dailyLimit = Math.max(MIN_WEIGHT_LOSS_CALORIES, maintenanceCalories - deficit);
  } else if (kind === 'gain') {
    dailyLimit += Math.min(MAX_WEIGHT_LOSS_DEFICIT, maintenanceCalories * 0.15);
  }

  return Math.round(Math.max(MIN_SAFE_DAILY_CALORIES, dailyLimit));
};

export const validateConsumptionService = async (userId, date) => {
  try {
    const day = resolveDateParam(date);
    const userData = await getUserNutritionalData(userId);

    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }

    const { age, goal, height, weight } = userData;

    if (!age || !height || !weight) {
      throw new AppError('Faltan datos físicos (edad, altura o peso) para calcular el objetivo', 400, 'MISSING_PHYSICAL_DATA');
    }

    const dailyLimit = calculateDailyLimit(userData);

    const totalConsumed = await getConsumptionCaloriesByDate(userId, day);

    const status = totalConsumed > dailyLimit ? 'EXCEDIDO' : 'OK';

    return {
      userId,
      goal: goal || 'No especificado',
      dailyLimit,
      totalConsumed: Math.round(totalConsumed),
      status,
      remaining: Math.max(0, Math.round(dailyLimit - totalConsumed))
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};

export const getTodayCaloriesService = async (userId, date) => {
  try {
    const day = resolveDateParam(date);
    const totalConsumed = await getConsumptionCaloriesByDate(userId, day);
    return {
      totalConsumed: Math.round(totalConsumed) || 0,
      unit: 'kcal',
      date: day
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};

export const getWeekStatsService = async (userId, end) => {
  try {
    const endDay = resolveDateParam(end);
    const startDay = addDays(endDay, -6);
    const [userData, days] = await Promise.all([
      getUserNutritionalData(userId),
      getDailyConsumptionRepository(userId, startDay, endDay),
    ]);
    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }
    const dailyLimit = calculateDailyLimit(userData);
    const total = days.reduce((sum, d) => sum + d.totalConsumed, 0);
    // Misma regla que la racha calórica.
    const range = dailyLimit === null ? null : calorieRange(goalKind(userData.goal), dailyLimit);
    const daysOnTarget = range === null
      ? 0
      : days.filter((d) => isGoalDay(d.totalConsumed, range)).length;
    return {
      start: startDay,
      end: endDay,
      dailyLimit,
      days,
      average: Math.round(total / days.length),
      daysOnTarget,
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};

/**
 * Racha del objetivo calórico con toda la historia de comidas.
 * @param {number} userId
 * @param {string} [date] Hoy de la app, YYYY-MM-DD
 */
export const getCalorieStreakService = async (userId, date) => {
  try {
    const today = resolveDateParam(date);
    const [userData, firstDay] = await Promise.all([
      getUserNutritionalData(userId),
      getFirstMealDateRepository(userId),
    ]);
    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }

    const dailyLimit = calculateDailyLimit(userData);
    if (dailyLimit === null) {
      return { current: null, best: null, dailyLimit: null, min: null, max: null };
    }

    const range = calorieRange(goalKind(userData.goal), dailyLimit);
    if (!firstDay || firstDay > today) {
      return { current: 0, best: 0, dailyLimit, ...range };
    }

    const days = await getDailyConsumptionRepository(userId, firstDay, today);
    const history = Object.fromEntries(days.map((d) => [d.date, d.totalConsumed]));
    return {
      current: currentCalorieStreak(history, today, range),
      best: bestCalorieStreak(history, range),
      dailyLimit,
      ...range,
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};
