import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getFridgeHealth, getFridgeItems } from './fridge.controller.js';

const router = Router();

router.get('/health', getFridgeHealth);
router.get('/', authenticateToken(['ADMIN', 'USER']), getFridgeItems);

export default router;
