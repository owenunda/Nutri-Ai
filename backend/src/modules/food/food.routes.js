import { Router } from 'express';
import * as FoodController from './food.controller.js';
import { validateListFoodsQuery } from './food.validation.js';
import authenticateToken from '../../middleware/auth.middleware.js';

const router = Router();

router.get('/health', FoodController.getFoodHealth);

router.get('/',
    authenticateToken(['ADMIN', 'USER']),
    validateListFoodsQuery,
    FoodController.getAllFoods
);

router.post('/',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.createFood
);

router.put('/:id',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.updateFood
);

router.delete('/:id',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.deleteFood
);

// ruta para matchear alimentos
router.post('/match', authenticateToken(['USER', 'ADMIN']), FoodController.matchFoods);

export default router;