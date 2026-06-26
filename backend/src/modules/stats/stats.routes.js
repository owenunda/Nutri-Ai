import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getConsumptionValidation, getTodayCalories } from './stats.controller.js';

const router = Router();

/**
 * @openapi
 * /api/v1/stats/consumption-validation:
 *   get:
 *     tags: [Stats]
 *     summary: Validar si el consumo calórico del usuario está dentro de su meta
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Resultado de la validación de consumo
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         isWithinGoal:
 *                           type: boolean
 *                         consumed:
 *                           type: number
 *                         target:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/consumption-validation',
  authenticateToken(['USER', 'ADMIN']),
  getConsumptionValidation
);

/**
 * @openapi
 * /api/v1/stats/today-calories:
 *   get:
 *     tags: [Stats]
 *     summary: Obtener calorías totales consumidas hoy
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Calorías consumidas en el día actual
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalCalories:
 *                           type: number
 *                           example: 1450.5
 *                         date:
 *                           type: string
 *                           format: date
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/today-calories',
  authenticateToken(['USER', 'ADMIN']),
  getTodayCalories
);

export default router;
