import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { createMeal, addMealItems, addMealRecipes } from './meal.controller.js';

const router = Router();

router.post('/', authenticateToken(['USER', 'ADMIN']), createMeal);
router.post('/:id/items', authenticateToken(['USER', 'ADMIN']), addMealItems);
router.post('/:id/recipes', authenticateToken(['USER', 'ADMIN']), addMealRecipes);

export default router;
