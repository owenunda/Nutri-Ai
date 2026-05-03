import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getFridgeHealth, getFridgeItems, addItemToFridge, updateFridgeItem } from './fridge.controller.js';
import { validateAddFridgeItem, validateUpdateFridgeItem } from './fridge.validation.js';

const router = Router();

router.get('/health', getFridgeHealth);
router.get('/', authenticateToken(['ADMIN', 'USER']), getFridgeItems);
router.post('/items', authenticateToken(['ADMIN', 'USER']), validateAddFridgeItem, addItemToFridge);
router.put('/items/:id', authenticateToken(['ADMIN', 'USER']), validateUpdateFridgeItem, updateFridgeItem);

export default router;
