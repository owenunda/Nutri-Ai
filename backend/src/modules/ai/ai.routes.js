import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { receiveGeneratedRecipe } from './ai.controller.js';

const router = Router();

/**
 * @route POST /api/v1/ai/recipe
 * @desc Recibe una receta de n8n o servicio externo y la guarda.
 * @access Private
 */
router.post('/recipe', authenticateToken(['USER', 'ADMIN']), receiveGeneratedRecipe);

export default router;
