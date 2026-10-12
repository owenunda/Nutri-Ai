import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { createMeal, addMealItems, addMealRecipes, getDayMeals, deleteMealItem } from './meal.controller.js';

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
 * /api/v1/meals/day:
 *   get:
 *     tags: [Meals]
 *     summary: Comidas del día agrupadas por tipo (desayuno, almuerzo, cena, snack) con sus kcal
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         required: false
 *         description: Fecha local YYYY-MM-DD (por defecto, el día UTC del servidor)
 *         schema:
 *           type: string
 *           format: date
 *           example: "2026-06-23"
 *     responses:
 *       200:
 *         description: Comidas del día obtenidas
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       400:
 *         description: Fecha inválida
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/day', authenticateToken(['USER', 'ADMIN']), getDayMeals);

/**
 * @openapi
 * /api/v1/meals/items/{detailId}:
 *   delete:
 *     tags: [Meals]
 *     summary: Eliminar un ítem propio de un registro de comida
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: detailId
 *         required: true
 *         description: ID del ítem (meal_record_detail_id)
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Ítem eliminado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       400:
 *         description: detailId inválido
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.delete('/items/:detailId', authenticateToken(['USER', 'ADMIN']), deleteMealItem);

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
 *               required: [food_id, quantity]
 *               properties:
 *                 food_id:
 *                   type: integer
 *                   example: 3
 *                 quantity:
 *                   type: number
 *                   example: 1.5
 *                 meal_type:
 *                   type: string
 *                   enum: [BREAKFAST, LUNCH, DINNER, SNACK]
 *                   default: SNACK
 *                   example: LUNCH
 *     responses:
 *       201:
 *         description: Ítems agregados al registro
 *       400:
 *         description: Cantidad o meal_type inválidos
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
