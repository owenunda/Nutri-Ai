import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
  createPhysical,
  getPhysicalHistoryController,
  getProfile,
  updateProfile,
} from './user.controller.js';
import {
  validateCreatePhysicalRecordRequest,
  validateUpdateProfileRequest,
} from './user.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/user/profile:
 *   get:
 *     tags: [User]
 *     summary: Obtener perfil del usuario autenticado
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Perfil del usuario
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/profile', authenticateToken(), getProfile);

/**
 * @openapi
 * /api/v1/user/physical/history:
 *   get:
 *     tags: [User]
 *     summary: Obtener historial de registros físicos del usuario
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Historial de medidas físicas
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
 *                         $ref: '#/components/schemas/PhysicalRecord'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/physical/history', authenticateToken(), getPhysicalHistoryController);

/**
 * @openapi
 * /api/v1/user/physical:
 *   post:
 *     tags: [User]
 *     summary: Registrar medidas físicas (peso, talla)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [height, weight]
 *             properties:
 *               height:
 *                 type: number
 *                 description: Altura en cm
 *                 example: 175
 *               weight:
 *                 type: number
 *                 description: Peso en kg
 *                 example: 70.5
 *     responses:
 *       201:
 *         description: Registro físico creado
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/PhysicalRecord'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/physical', authenticateToken(), validateCreatePhysicalRecordRequest, createPhysical);

/**
 * @openapi
 * /api/v1/user/profile:
 *   put:
 *     tags: [User]
 *     summary: Actualizar perfil del usuario
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: Juan Pérez
 *               goal:
 *                 type: string
 *                 example: ganar músculo
 *     responses:
 *       200:
 *         description: Perfil actualizado
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.put('/profile', authenticateToken(), validateUpdateProfileRequest, updateProfile);

export default router;
