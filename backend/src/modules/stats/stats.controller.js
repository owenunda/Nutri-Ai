import { validateConsumptionService, getTodayCaloriesService } from './stats.service.js';
import { successResponse } from '../../utils/response.js';

/**
 * Controlador para obtener la validación del consumo diario.
 */
export const getConsumptionValidation = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const validationResult = await validateConsumptionService(userId);

    return successResponse(
      res, 
      validationResult, 
      'Validación de consumo realizada con éxito', 
      200
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Obtiene el total de calorías consumidas hoy.
 */
export const getTodayCalories = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const stats = await getTodayCaloriesService(userId);
    return successResponse(res, stats, 'Total de calorías consultado con éxito');
  } catch (error) {
    next(error);
  }
};
