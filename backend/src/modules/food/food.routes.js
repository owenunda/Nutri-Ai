import { Router } from 'express';
import * as FoodController from './food.controller.js';
import authenticateToken from '../../middleware/auth.middleware.js';


const router = Router();

// Ruta de verificación del modulo

router.get('/health', FoodController.getFoodHealth);

// Ruta base del modulo

router.get('/',
    authenticateToken(['ADMIN', 'USER']),
    FoodController.getAllFoods
);

// Tu nueva ruta POST para crear alimentos
router.post('/',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.createFood
);

export default router;