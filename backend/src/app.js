import express from 'express';
import cors from 'cors';
import foodRoutes from './modules/food/food.routes.js';
import fridgeRoutes from './modules/fridge/fridge.routes.js';
import recipeRoutes from './modules/recipe/recipe.routes.js';
import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/user/user.routes.js';
import authenticateToken from './middleware/auth.middleware.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';
import { errorResponse, successResponse } from './utils/response.js';
import { sendChatN8n } from './utils/n8n.service.js';

const app = express();

// Middlewares globales
app.use(cors());
app.use(express.json());

// Ruta de prueba general
app.get('/api/v1/health', (req, res) => {
  res.json({
    success: true,
    data: null,
    message: 'NutriAI API is running'
  });
});

app.post('/api/v1/n8n/chat', authenticateToken(['ADMIN', 'USER']), async (req, res) => {
  try {
    const { message } = req.body;
    const { userId, name } = req.user;
    if (!message) throw new AppError("Bad request", 400, "BAD_REQUEST");

    const result = await sendChatN8n(message, userId, name);
    return successResponse(res, result, 'Mensaje enviado correctamente a n8n');
  } catch (error) {
    errorResponse(res, error.message, error.code, error.status, error.details);
  }
})


// Rutas del módulo food
app.use('/api/v1/food', foodRoutes);
app.use('/api/v1/fridge', fridgeRoutes);

// Rutas del módulo recipe
app.use('/api/v1/recipe', recipeRoutes)

// Rutas del módulo auth
app.use('/api/v1/auth', authRoutes);

// Rutas del módulo user 
app.use('/api/v1/user', userRoutes);

// Middleware para rutas no encontradas
app.use(notFoundHandler);

// Middleware global de errores
app.use(errorHandler);

export default app;
