import { Router } from 'express';
import * as FoodController from './food.controller.js';
import { validateListFoodsQuery } from './food.validation.js';
import authenticateToken from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @openapi
 * /api/v1/food/health:
 *   get:
 *     tags: [Food]
 *     summary: Estado del módulo de alimentos
 *     security: []
 *     responses:
 *       200:
 *         description: Módulo activo
 */
router.get('/health', FoodController.getFoodHealth);

/**
 * @openapi
 * /api/v1/food:
 *   get:
 *     tags: [Food]
 *     summary: Listar alimentos (globales + propios del usuario)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           example: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           example: 20
 *     responses:
 *       200:
 *         description: Lista de alimentos
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
 *                         foods:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Food'
 *                         pagination:
 *                           type: object
 *                           properties:
 *                             page:
 *                               type: integer
 *                             limit:
 *                               type: integer
 *                             totalItems:
 *                               type: integer
 *                             totalPages:
 *                               type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/',
    authenticateToken(['ADMIN', 'USER']),
    validateListFoodsQuery,
    FoodController.getAllFoods
);

/**
 * @openapi
 * /api/v1/food:
 *   post:
 *     tags: [Food]
 *     summary: Crear alimento personalizado
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, calories_per_unit, base_unit]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Arroz integral
 *               calories_per_unit:
 *                 type: number
 *                 example: 3.5
 *               base_unit:
 *                 type: string
 *                 example: g
 *     responses:
 *       201:
 *         description: Alimento creado
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.createFood
);

/**
 * @openapi
 * /api/v1/food/{id}:
 *   put:
 *     tags: [Food]
 *     summary: Actualizar alimento propio
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               calories_per_unit:
 *                 type: number
 *               base_unit:
 *                 type: string
 *     responses:
 *       200:
 *         description: Alimento actualizado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put('/:id',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.updateFood
);

/**
 * @openapi
 * /api/v1/food/{id}:
 *   delete:
 *     tags: [Food]
 *     summary: Desactivar alimento propio
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Alimento desactivado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: No autorizado para desactivar este alimento
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.delete('/:id',
    authenticateToken(['USER', 'ADMIN']),
    FoodController.deleteFood
);

/**
 * @openapi
 * /api/v1/food/match:
 *   post:
 *     tags: [Food]
 *     summary: Mapear lista de ingredientes a alimentos de la base de datos
 *     description: Recibe un array de ingredientes (nombre + cantidad) y retorna los alimentos que coincidan en la DB, filtrando por alimentos globales o del usuario. Útil para procesar la respuesta del agente n8n.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [ingredients]
 *             properties:
 *               ingredients:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/Ingredient'
 *             example:
 *               ingredients:
 *                 - name: tomates
 *                   quantity: 3
 *                 - name: pollo
 *                   quantity: 1
 *     responses:
 *       200:
 *         description: Alimentos encontrados en la DB para los ingredientes dados
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
 *                         $ref: '#/components/schemas/MatchedFood'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/match', authenticateToken(['USER', 'ADMIN']), FoodController.matchFoods);

export default router;
