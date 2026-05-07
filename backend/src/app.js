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
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

const app = express();

// Middlewares globales
app.use(cors());
app.use(express.json());

// Documentación de la API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/api/v1/health', (req, res) => {
  res.json({
    success: true,
    data: null,
    message: 'NutriAI API is running'
  });
});


app.use('/api/v1/food', foodRoutes);
app.use('/api/v1/fridge', fridgeRoutes);

app.use('/api/v1/recipe', recipeRoutes)

app.use('/api/v1/auth', authRoutes);

app.use('/api/v1/user', userRoutes);

app.use('/api/v1/stats', statsRoutes);

app.use('/api/v1/meals', mealRoutes);

app.use('/api/v1/ai', aiRoutes);

app.use(notFoundHandler);

app.use(errorHandler);

export default app;
