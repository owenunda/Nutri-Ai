import express from 'express';
import cors from 'cors';

const app = express();

// Middlewares globales
app.use(cors()); // podemos usar cors() para permitir peticiones desde cualquier origen
app.use(express.json()); // podemos usar express.json() para permitir peticiones con body en formato json

// Ruta de prueba
app.get('/health', (req, res) => {
  res.json({ message: 'NutriAI API is running' });
});

export default app;
