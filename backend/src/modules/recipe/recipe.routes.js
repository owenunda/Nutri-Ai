import { Router } from "express";
import { getAllRecipes, createRecipe, addIngredientsToRecipe, getRecipeById, updateRecipeStatus, handleRecipeAction } from "./recipe.controller.js";
import authenticateToken from "../../middleware/auth.middleware.js";

const router = Router();

/**
 * @openapi
 * /api/v1/recipe:
 *   get:
 *     tags: [Recipes]
 *     summary: Listar recetas del usuario
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de recetas
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Recipe'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/', authenticateToken(['ADMIN', 'USER']), getAllRecipes);

/**
 * @openapi
 * /api/v1/recipe/{recipeId}:
 *   get:
 *     tags: [Recipes]
 *     summary: Obtener receta por ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipeId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Receta encontrada
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
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/:recipeId', authenticateToken(['ADMIN', 'USER']), getRecipeById);

/**
 * @openapi
 * /api/v1/recipe:
 *   post:
 *     tags: [Recipes]
 *     summary: Crear nueva receta
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Ensalada César
 *               description:
 *                 type: string
 *                 example: Receta clásica con pollo
 *     responses:
 *       201:
 *         description: Receta creada
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/', authenticateToken(['ADMIN', 'USER']), createRecipe);

/**
 * @openapi
 * /api/v1/recipe/{recipeId}/ingredients:
 *   post:
 *     tags: [Recipes]
 *     summary: Agregar ingredientes a una receta
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipeId
 *         required: true
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
 *                   example: 100
 *                 unit:
 *                   type: string
 *                   example: g
 *     responses:
 *       200:
 *         description: Ingredientes agregados
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/:recipeId/ingredients', authenticateToken(['ADMIN', 'USER']), addIngredientsToRecipe);

/**
 * @openapi
 * /api/v1/recipe/{recipeId}/status:
 *   patch:
 *     tags: [Recipes]
 *     summary: Actualizar estado de una receta
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipeId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 example: completed
 *     responses:
 *       200:
 *         description: Estado actualizado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.patch('/:recipeId/status', authenticateToken(['ADMIN', 'USER']), updateRecipeStatus);

/**
 * @openapi
 * /api/v1/recipe/{recipeId}/action:
 *   post:
 *     tags: [Recipes]
 *     summary: Ejecutar acción sobre una receta (ej. favorita, archivar)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipeId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [action]
 *             properties:
 *               action:
 *                 type: string
 *                 example: favorite
 *     responses:
 *       200:
 *         description: Acción ejecutada
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/:recipeId/action', authenticateToken(['ADMIN', 'USER']), handleRecipeAction);

export default router;
