import { validateConsumptionService, getTodayCaloriesService, getWeekStatsService } from './stats.service.js';
import { successResponse } from '../../utils/response.js';

export const getConsumptionValidation = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const validationResult = await validateConsumptionService(userId, req.query.date);

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

export const getTodayCalories = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const stats = await getTodayCaloriesService(userId, req.query.date);
    return successResponse(res, stats, 'Total de calorías consultado con éxito');
  } catch (error) {
    next(error);
  }
};

export const getWeekStats = async (req, res, next) => {
  try {
    const stats = await getWeekStatsService(req.user.userId, req.query.end);
    return successResponse(res, stats, 'Resumen semanal consultado con éxito');
  } catch (error) {
    next(error);
  }
};
