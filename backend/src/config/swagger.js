import swaggerJsdoc from 'swagger-jsdoc';
import { config } from './env_config.js';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'NutriAI API',
      version: '1.0.0',
      description: 'NutriAI API',
      contact: {
        name: 'SENA NutriAI Team',
      },
    },
    servers: [
      {
        url: `http://localhost:${config.port || 3000}`,
        description: 'Servidor Local',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: [
    './src/app.js', 
    './src/config/swagger.schemas.js', 
    './src/**/*.swagger.yaml',
    './src/modules/**/*.routes.js'
  ], 
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
