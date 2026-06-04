import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getFridgeHealth, getFridgeItems, addItemToFridge, updateFridgeItem, deleteFridgeItem } from './fridge.controller.js';
import { validateAddFridgeItem, validateUpdateFridgeItem, validateDeleteFridgeItem } from './fridge.validation.js';

const router = Router();

router.get('/health', getFridgeHealth);
router.get('/', authenticateToken(['ADMIN', 'USER']), getFridgeItems);
router.post('/items', authenticateToken(['ADMIN', 'USER']), validateAddFridgeItem, addItemToFridge);
router.put('/items/:id', authenticateToken(['ADMIN', 'USER']), validateUpdateFridgeItem, updateFridgeItem);
router.delete('/items/:id', authenticateToken(['ADMIN', 'USER']), validateDeleteFridgeItem, deleteFridgeItem);

export default router;
