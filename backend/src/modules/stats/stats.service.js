import { getUserNutritionalData, getTodayConsumptionCalories } from './stats.repository.js';
import { AppError } from '../../utils/AppError.js';

/**
 * Valida el consumo de calorías del día actual frente al objetivo del usuario.
 * @param {number} userId 
 * @returns {Promise<Object>}
 */
export const validateConsumptionService = async (userId) => {
  try {
    const userData = await getUserNutritionalData(userId);

    if (!userData) {
      throw new AppError('Usuario no encontrado', 404, 'USER_NOT_FOUND');
    }

    const { age, goal, height, weight } = userData;

    // Verificar que tengamos los datos mínimos para el cálculo
    if (!age || !height || !weight) {
      throw new AppError('Faltan datos físicos (edad, altura o peso) para calcular el objetivo', 400, 'MISSING_PHYSICAL_DATA');
    }

    // Cálculo de BMR (Fórmula de Mifflin-St Jeor - Promedio neutral)
    // BMR = 10 * peso (kg) + 6.25 * altura (cm) - 5 * edad (y) - 80
    const bmr = (10 * parseFloat(weight)) + (6.25 * parseFloat(height)) - (5 * parseInt(age)) - 80;

    // Ajuste según el objetivo
    let dailyLimit = bmr;
    const normalizedGoal = goal?.toLowerCase() || '';

    if (normalizedGoal.includes('perder') || normalizedGoal.includes('lose')) {
      dailyLimit -= 500;
    } else if (normalizedGoal.includes('ganar') || normalizedGoal.includes('gain')) {
      dailyLimit += 500;
    }

    // Obtener consumo de hoy
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
