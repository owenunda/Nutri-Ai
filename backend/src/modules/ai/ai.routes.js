import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { receiveGeneratedRecipe } from './ai.controller.js';

const router = Router();

/**
 * @openapi
 * /api/v1/ai/recipe:
 *   post:
 *     tags: [AI]
 *     summary: Recibir receta generada por el agente de IA (webhook interno)
 *     description: Endpoint llamado por n8n para persistir una receta generada automáticamente para el usuario.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, ingredients]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Pollo al limón con arroz
 *               description:
 *                 type: string
 *                 example: Receta alta en proteína generada por IA
 *               ingredients:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/Ingredient'
 *     responses:
 *       201:
 *         description: Receta persistida correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Recipe'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/recipe', authenticateToken(['USER', 'ADMIN']), receiveGeneratedRecipe);

export default router;
