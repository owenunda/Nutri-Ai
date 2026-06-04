import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { receiveGeneratedRecipe } from './ai.controller.js';

const router = Router();

router.post('/recipe', authenticateToken(['USER', 'ADMIN']), receiveGeneratedRecipe);

export default router;
