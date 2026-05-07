import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getConsumptionValidation, getTodayCalories } from './stats.controller.js';

const router = Router();

router.get('/consumption-validation', 
  authenticateToken(['USER', 'ADMIN']), 
  getConsumptionValidation
);

router.get('/today-calories',
  authenticateToken(['USER', 'ADMIN']),
  getTodayCalories
);

export default router;
