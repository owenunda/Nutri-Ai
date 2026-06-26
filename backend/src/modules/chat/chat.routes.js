import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
    getActiveSessionController,
    createSessionController,
    updateConversationStateController,
    addMessageController,
    closeSessionController
} from './chat.controller.js';
import {
    validateAddMessageRequest,
    validateUpdateConversationStateRequest
} from './chat.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/chat/session:
 *   get:
 *     tags: [Chat]
 *     summary: Obtener sesión activa del usuario
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Sesión activa encontrada o indicador de ausencia
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
 *                         hasActiveSession:
 *                           type: boolean
 *                           example: true
 *                         session:
 *                           $ref: '#/components/schemas/ChatSession'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/session', authenticateToken(['ADMIN', 'USER']), getActiveSessionController);

/**
 * @openapi
 * /api/v1/chat/session:
 *   post:
 *     tags: [Chat]
 *     summary: Crear una nueva sesión conversacional
 *     description: Solo se permite una sesión activa por usuario. Si ya existe una sesión activa se devuelve 409.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       201:
 *         description: Sesión creada correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/ChatSession'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       409:
 *         description: El usuario ya tiene una sesión activa
 */
router.post('/session', authenticateToken(['ADMIN', 'USER']), createSessionController);

/**
 * @openapi
 * /api/v1/chat/session:
 *   put:
 *     tags: [Chat]
 *     summary: Actualizar el conversation_state de la sesión activa
 *     description: Reemplaza completamente el conversation_state con la estructura proporcionada.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ConversationState'
 *     responses:
 *       200:
 *         description: Estado actualizado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/ChatSession'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: No hay sesión activa
 */
router.put('/session', authenticateToken(['ADMIN', 'USER']), validateUpdateConversationStateRequest, updateConversationStateController);

/**
 * @openapi
 * /api/v1/chat/session/message:
 *   post:
 *     tags: [Chat]
 *     summary: Agregar un mensaje a la sesión activa
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [role, content]
 *             properties:
 *               role:
 *                 type: string
 *                 enum: [USER, ASSISTANT]
 *                 example: USER
 *               content:
 *                 type: string
 *                 example: Hazla para 4 personas
 *     responses:
 *       201:
 *         description: Mensaje agregado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/ChatMessage'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: No hay sesión activa
 */
router.post('/session/message', authenticateToken(['ADMIN', 'USER']), validateAddMessageRequest, addMessageController);

/**
 * @openapi
 * /api/v1/chat/session/close:
 *   put:
 *     tags: [Chat]
 *     summary: Cerrar la sesión activa
 *     description: Marca la sesión como inactiva. Los registros nunca se eliminan.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Sesión cerrada correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/ChatSession'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: No hay sesión activa
 */
router.put('/session/close', authenticateToken(['ADMIN', 'USER']), closeSessionController);

export default router;
