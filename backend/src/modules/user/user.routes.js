import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
  createPhysical,
  deleteAccount,
  getPhysicalHistoryController,
  getProfile,
  setPassword,
  updateProfile,
} from './user.controller.js';
import {
  validateCreatePhysicalRecordRequest,
  validateDeleteAccountRequest,
  validateSetPasswordRequest,
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

/**
 * @openapi
 * /api/v1/user/account:
 *   delete:
 *     tags: [User]
 *     summary: Eliminar la cuenta del usuario y todos sus datos
 *     description: Borra de forma permanente el usuario, sus comidas, nevera, registros físicos, chats, recetas y alimentos personalizados. Exige la contraseña actual, o un idToken de Google si la cuenta no tiene contraseña.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               password:
 *                 type: string
 *                 example: MiContraseña123
 *               googleIdToken:
 *                 type: string
 *                 description: Solo para cuentas sin contraseña
 *     responses:
 *       200:
 *         description: Cuenta eliminada
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         description: Confirmación incorrecta (code INVALID_PASSWORD, INVALID_GOOGLE_TOKEN o GOOGLE_ACCOUNT_MISMATCH)
 *       404:
 *         description: El usuario ya no existe
 */
router.delete('/account', authenticateToken(), validateDeleteAccountRequest, deleteAccount);

/**
 * @openapi
 * /api/v1/user/password:
 *   post:
 *     tags: [User]
 *     summary: Crear la contraseña de una cuenta que solo entra con Google
 *     description: Solo funciona si la cuenta no tiene contraseña. Después el usuario puede entrar con Google o con email y contraseña.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [password]
 *             properties:
 *               password:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Contraseña creada
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       409:
 *         description: La cuenta ya tiene contraseña (code PASSWORD_ALREADY_SET)
 */
router.post('/password', authenticateToken(), validateSetPasswordRequest, setPassword);

export default router;
