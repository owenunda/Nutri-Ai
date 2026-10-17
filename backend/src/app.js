import express from 'express';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger.js';
import foodRoutes from './modules/food/food.routes.js';
import fridgeRoutes from './modules/fridge/fridge.routes.js';
import recipeRoutes from './modules/recipe/recipe.routes.js';
import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/user/user.routes.js';
import statsRoutes from './modules/stats/stats.routes.js';
import mealRoutes from './modules/meal/meal.routes.js';
import aiRoutes from './modules/ai/ai.routes.js';
import chatRoutes from './modules/chat/chat.routes.js';
import { sendChatMessageController } from './modules/chat/chatMessage.controller.js';
import eventsRoutes from './modules/events/events.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';
import authenticateToken from './middleware/auth.middleware.js';
import { chatRateLimit } from './middleware/rateLimit.middleware.js';
import { chatDailyQuota } from './middleware/chatQuota.middleware.js';
import { activityLogger } from './middleware/activityLogger.middleware.js';
import { languageMiddleware } from './middleware/language.middleware.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

const app = express();

// En producción hay un único proxy delante (Coolify). Sin esto req.ip es la IP
// del proxy para todas las peticiones, y los límites por IP se comparten entre
// todos los clientes.
app.set('trust proxy', 1);

// Middlewares globales
app.use(cors());
app.use(express.json());

// Idioma de la respuesta (errores, correos, chat) según Accept-Language.
app.use(languageMiddleware);

// Captura automática de eventos de actividad (best-effort, no bloqueante)
app.use(activityLogger);

// Documentación de la API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/api/v1/health', (_req, res) => {
  res.json({
    success: true,
    data: null,
    message: 'NutriLife API is running'
  });
});

/**
 * @openapi
 * /api/v1/n8n/chat:
 *   post:
 *     tags: [N8N]
 *     summary: Enviar mensaje al agente de IA vía n8n
 *     description: Recibe un mensaje del usuario y lo reenvía al webhook de n8n junto con el userId, nombre y token JWT del usuario autenticado. n8n procesa el mensaje con el agente de IA y retorna la respuesta.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ChatRequest'
 *           examples:
 *             con_ingredientes:
 *               summary: Usuario menciona alimentos
 *               value:
 *                 message: "necesito un desayuno, tengo 3 huevos y 2 cebollas"
 *             sin_ingredientes:
 *               summary: Usuario solo pide comida
 *               value:
 *                 message: "quiero ideas para la cena"
 *     responses:
 *       200:
 *         description: JSON estructurado generado por el agente de IA
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
 *                         intent:
 *                           type: string
 *                           enum: [GENERATE_RECIPE_WITH_INPUT, GENERATE_RECIPE_FROM_FRIDGE, UNKNOWN]
 *                           example: GENERATE_RECIPE_WITH_INPUT
 *                         ingredients:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Ingredient'
 *                         meal_type:
 *                           type: string
 *                           nullable: true
 *                           enum: [desayuno, almuerzo, cena, null]
 *                           example: desayuno
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       429:
 *         description: Límite por minuto (RATE_LIMIT_EXCEEDED) o del día (CHAT_DAILY_LIMIT para FREE, CHAT_FAIR_USE_LIMIT para PRO). Los del día traen data.quota.
 *       503:
 *         description: El servicio de IA no responde (N8N_ERROR). El mensaje no cuenta para el límite.
 */
app.post('/api/v1/n8n/chat', authenticateToken(['ADMIN', 'USER']), chatRateLimit, chatDailyQuota, sendChatMessageController);

app.use('/api/v1/food', foodRoutes);
app.use('/api/v1/fridge', fridgeRoutes);
app.use('/api/v1/recipe', recipeRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/stats', statsRoutes);
app.use('/api/v1/meals', mealRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/chat', chatRoutes);
app.use('/api/v1/admin/events', eventsRoutes);
app.use('/api/v1/admin', adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
