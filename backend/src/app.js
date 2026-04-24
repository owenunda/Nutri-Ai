import express from 'express';
import cors from 'cors';
import foodRoutes from './modules/food/food.routes.js';
import recipeRoutes from './modules/recipe/recipe.routes.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

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

// Rutas del módulo food
app.use('/foods', foodRoutes);
app.use('/api/v1/recipe', recipeRoutes)

// Middleware para rutas no encontradas
app.use(notFoundHandler);

// Middleware global de errores
app.use(errorHandler);

export default app;
