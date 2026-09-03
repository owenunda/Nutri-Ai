import swaggerJsdoc from 'swagger-jsdoc';
import { config } from './env_config.js';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'NutriLife API',
      version: '1.0.0',
      description: 'NutriLife API',
      contact: {
        name: 'SENA NutriLife Team',
      },
    },
    servers: [
      ...(config.node_env !== 'development' ? [{
        url: 'https://api.nutri.oween.software',
        description: 'Servidor Producción',
      }] : []),
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
