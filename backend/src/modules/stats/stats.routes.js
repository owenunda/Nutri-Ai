import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getConsumptionValidation, getTodayCalories } from './stats.controller.js';

const router = Router();

/**
 * @route GET /api/v1/stats/consumption-validation
 * @desc Obtiene la validación del consumo diario frente al objetivo.
 * @access Private
 */
router.get('/consumption-validation', 
  authenticateToken(['USER', 'ADMIN']), 
  getConsumptionValidation
);

/**
 * @route GET /api/v1/stats/today-calories
 * @desc Obtiene el total de calorías consumidas hoy.
 * @access Private
 */
router.get('/today-calories',
  authenticateToken(['USER', 'ADMIN']),
  getTodayCalories
);

export default router;
