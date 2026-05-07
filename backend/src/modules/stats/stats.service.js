import { getUserNutritionalData, getTodayConsumptionCalories } from './stats.repository.js';
import { AppError } from '../../utils/AppError.js';

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

    const bmr = (10 * parseFloat(weight)) + (6.25 * parseFloat(height)) - (5 * parseInt(age)) - 80;

    let dailyLimit = bmr;
    const normalizedGoal = goal?.toLowerCase() || '';

    if (normalizedGoal.includes('perder') || normalizedGoal.includes('lose')) {
      dailyLimit -= 500;
    } else if (normalizedGoal.includes('ganar') || normalizedGoal.includes('gain')) {
      dailyLimit += 500;
    }

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
