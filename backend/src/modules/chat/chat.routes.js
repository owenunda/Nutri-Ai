import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
    getActiveSessionController,
    getSessionsController,
    createSessionController,
    updateConversationStateController,
    addMessageController,
    closeSessionController,
    getSessionMessagesController,
    activateSessionController
} from './chat.controller.js';
import { getChatQuotaController } from './chatQuota.controller.js';
import {
    validateSessionIdParam,
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
router.get('/sessions', authenticateToken(['ADMIN', 'USER']), getSessionsController);

/**
 * @openapi
 * /api/v1/chat/sessions/{sessionId}/messages:
 *   get:
 *     tags: [Chat]
 *     summary: Obtener una sesión del usuario con todos sus mensajes
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Sesión y mensajes en orden cronológico
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
 *                         session:
 *                           $ref: '#/components/schemas/ChatSession'
 *                         messages:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/ChatMessage'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: La sesión no existe o no pertenece al usuario
 */
router.get('/sessions/:sessionId/messages', authenticateToken(['ADMIN', 'USER']), validateSessionIdParam, getSessionMessagesController);

/**
 * @openapi
 * /api/v1/chat/sessions/{sessionId}/activate:
 *   put:
 *     tags: [Chat]
 *     summary: Retomar una sesión anterior
 *     description: Cierra la sesión activa actual y deja activa la indicada, para que el chat continúe sobre ella.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sessionId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Sesión activada correctamente
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
 *         description: La sesión no existe o no pertenece al usuario
 */
router.put('/sessions/:sessionId/activate', authenticateToken(['ADMIN', 'USER']), validateSessionIdParam, activateSessionController);

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
 *               metadata:
 *                 type: object
 *                 nullable: true
 *                 description: Datos para repintar el mensaje en el historial (tipo de respuesta, acciones). Máximo 4 KB.
 *                 example: { type: ANSWER, actions: { steps: { focus_step: 3 }, tip: Agrega limón } }
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

/**
 * @openapi
 * /api/v1/chat/quota:
 *   get:
 *     tags: [Chat]
 *     summary: Mensajes del Chef IA que le quedan hoy al usuario
 *     description: >
 *       No consume mensajes. Para PRO y ADMIN unlimited es true y limit, used
 *       y remaining vienen null. data es null si Redis no está disponible.
 *       El día cambia a la medianoche de Bogotá (resetAt).
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cuota de hoy
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/quota', authenticateToken(['ADMIN', 'USER']), getChatQuotaController);

export default router;
