import { getUserNutritionalData, getTodayConsumptionCalories } from './stats.repository.js';
import { AppError } from '../../utils/AppError.js';

const ACTIVITY_FACTOR = 1.2;
const MAX_WEIGHT_LOSS_DEFICIT = 500;
const WEIGHT_LOSS_DEFICIT_RATIO = 0.15;
const MIN_WEIGHT_LOSS_CALORIES = 1200;
const MIN_SAFE_DAILY_CALORIES = 1200;

export const validateConsumptionService = async (userId) => {
  try {
    const userData = await getUserNutritionalData(userId);

    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }

    const { age, goal, height, weight } = userData;

    if (!age || !height || !weight) {
      throw new AppError('Faltan datos físicos (edad, altura o peso) para calcular el objetivo', 400, 'MISSING_PHYSICAL_DATA');
    }

    const parsedHeight = parseFloat(height);
    const heightInCentimeters = parsedHeight <= 3 ? parsedHeight * 100 : parsedHeight;
    const bmr = (10 * parseFloat(weight)) + (6.25 * heightInCentimeters) - (5 * parseInt(age)) - 80;
    const maintenanceCalories = bmr * ACTIVITY_FACTOR;

    let dailyLimit = maintenanceCalories;
    const normalizedGoal = goal?.toLowerCase() || '';

    if (
      normalizedGoal.includes('perder') ||
      normalizedGoal.includes('bajar') ||
      normalizedGoal.includes('lose')
    ) {
      const deficit = Math.min(
        MAX_WEIGHT_LOSS_DEFICIT,
        maintenanceCalories * WEIGHT_LOSS_DEFICIT_RATIO
      );
      dailyLimit = Math.max(MIN_WEIGHT_LOSS_CALORIES, maintenanceCalories - deficit);
    } else if (
      normalizedGoal.includes('ganar') ||
      normalizedGoal.includes('subir') ||
      normalizedGoal.includes('gain')
    ) {
      dailyLimit += Math.min(MAX_WEIGHT_LOSS_DEFICIT, maintenanceCalories * 0.15);
    }

    dailyLimit = Math.max(MIN_SAFE_DAILY_CALORIES, dailyLimit);

    const totalConsumed = await getTodayConsumptionCalories(userId);

    const status = totalConsumed > dailyLimit ? 'EXCEDIDO' : 'OK';

    return {
      userId,
      goal: goal || 'No especificado',
      dailyLimit: Math.round(dailyLimit),
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

export const getTodayCaloriesService = async (userId) => {
  try {
    const totalConsumed = await getTodayConsumptionCalories(userId);
    return {
      totalConsumed: Math.round(totalConsumed) || 0,
      unit: 'kcal',
      date: new Date().toISOString().split('T')[0]
    };
  } catch (error) {
    throw new AppError(error.message, 500, 'STATS_SERVICE_ERROR');
  }
};
