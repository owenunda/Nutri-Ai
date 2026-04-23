import { Router } from 'express';
import { getAllFoods, getFoodHealth } from './food.controller.js';

const router = Router();

// Ruta de verificacióon del modulo
router.get('/health', getFoodHealth);

// Ruta base del modulo
router.get('/', getAllFoods);

export default router;
