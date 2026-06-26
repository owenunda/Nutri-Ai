import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getFridgeHealth, getFridgeItems, addItemToFridge, updateFridgeItem, deleteFridgeItem } from './fridge.controller.js';
import { validateAddFridgeItem, validateUpdateFridgeItem, validateDeleteFridgeItem } from './fridge.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/fridge/health:
 *   get:
 *     tags: [Fridge]
 *     summary: Estado del módulo nevera
 *     security: []
 *     responses:
 *       200:
 *         description: Módulo activo
 */
router.get('/health', getFridgeHealth);

/**
 * @openapi
 * /api/v1/fridge:
 *   get:
 *     tags: [Fridge]
 *     summary: Obtener contenido de la nevera del usuario
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de ítems en la nevera
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
 *                         $ref: '#/components/schemas/FridgeItem'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/', authenticateToken(['ADMIN', 'USER']), getFridgeItems);

/**
 * @openapi
 * /api/v1/fridge/items:
 *   post:
 *     tags: [Fridge]
 *     summary: Agregar ítem a la nevera
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [foodId, quantity, unit]
 *             properties:
 *               foodId:
 *                 type: integer
 *                 example: 5
 *               quantity:
 *                 type: number
 *                 example: 200
 *               unit:
 *                 type: string
 *                 example: g
 *     responses:
 *       201:
 *         description: Ítem agregado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/items', authenticateToken(['ADMIN', 'USER']), validateAddFridgeItem, addItemToFridge);

/**
 * @openapi
 * /api/v1/fridge/items/{id}:
 *   put:
 *     tags: [Fridge]
 *     summary: Actualizar ítem de la nevera
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
 *               quantity:
 *                 type: number
 *               unit:
 *                 type: string
 *     responses:
 *       200:
 *         description: Ítem actualizado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put('/items/:id', authenticateToken(['ADMIN', 'USER']), validateUpdateFridgeItem, updateFridgeItem);

/**
 * @openapi
 * /api/v1/fridge/items/{id}:
 *   delete:
 *     tags: [Fridge]
 *     summary: Eliminar ítem de la nevera
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
 *         description: Ítem eliminado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.delete('/items/:id', authenticateToken(['ADMIN', 'USER']), validateDeleteFridgeItem, deleteFridgeItem);

export default router;
