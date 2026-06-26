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
import authenticateToken from './middleware/auth.middleware.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';
import { errorResponse, successResponse } from './utils/response.js';
import { sendChatN8n } from './utils/n8n.service.js';
import { AppError } from './utils/AppError.js';

const app = express();

// Middlewares globales
app.use(cors());
app.use(express.json());

// Documentación de la API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/api/v1/health', (_req, res) => {
  res.json({
    success: true,
    data: null,
    message: 'NutriAI API is running'
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
 *       500:
 *         description: Error al comunicarse con n8n
 */
app.post('/api/v1/n8n/chat', authenticateToken(['ADMIN', 'USER']), async (req, res) => {
  try {
    const { message } = req.body;
    const { userId, name } = req.user;
    const token = req.headers.authorization?.split(" ")[1];

    if (!message) throw new AppError("Bad request", 400, "BAD_REQUEST");

    const result = await sendChatN8n(message, userId, name, token);
    return successResponse(res, result, 'Mensaje enviado correctamente a n8n');
  } catch (error) {
    errorResponse(res, error.message, error.code, error.status, error.details);
  }
});

app.use('/api/v1/food', foodRoutes);
app.use('/api/v1/fridge', fridgeRoutes);
app.use('/api/v1/recipe', recipeRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/stats', statsRoutes);
app.use('/api/v1/meals', mealRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/chat', chatRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
