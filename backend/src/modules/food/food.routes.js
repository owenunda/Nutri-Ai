import { Router } from 'express';
import { getAllFoods, getFoodHealth } from './food.controller.js';
import { validateListFoodsQuery } from './food.validation.js';

const router = Router();

// Ruta de verificación del modulo
router.get('/health', getFoodHealth);

// Ruta base del modulo
router.get('/', validateListFoodsQuery, getAllFoods);

export default router;
