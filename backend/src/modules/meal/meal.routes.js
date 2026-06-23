import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { createMeal, addMealItems, addMealRecipes } from './meal.controller.js';

const router = Router();

/**
 * @openapi
 * /api/v1/meals:
 *   post:
 *     tags: [Meals]
 *     summary: Crear registro de comida del día
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *                 example: "2026-06-23"
 *     responses:
 *       201:
 *         description: Registro de comida creado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/', authenticateToken(['USER', 'ADMIN']), createMeal);

/**
 * @openapi
 * /api/v1/meals/{id}/items:
 *   post:
 *     tags: [Meals]
 *     summary: Agregar alimentos consumidos a un registro de comida
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del registro de comida
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: array
 *             items:
 *               type: object
 *               required: [foodId, quantity, unit]
 *               properties:
 *                 foodId:
 *                   type: integer
 *                   example: 3
 *                 quantity:
 *                   type: number
 *                   example: 150
 *                 unit:
 *                   type: string
 *                   example: g
 *     responses:
 *       200:
 *         description: Ítems agregados al registro
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/:id/items', authenticateToken(['USER', 'ADMIN']), addMealItems);

/**
 * @openapi
 * /api/v1/meals/{id}/recipes:
 *   post:
 *     tags: [Meals]
 *     summary: Agregar recetas consumidas a un registro de comida
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del registro de comida
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: array
 *             items:
 *               type: object
 *               required: [recipeId, servings]
 *               properties:
 *                 recipeId:
 *                   type: integer
 *                   example: 2
 *                 servings:
 *                   type: number
 *                   example: 1
 *     responses:
 *       200:
 *         description: Recetas agregadas al registro
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/:id/recipes', authenticateToken(['USER', 'ADMIN']), addMealRecipes);

export default router;
