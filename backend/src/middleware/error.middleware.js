import { AppError } from '../utils/appError.js';
import { errorResponse } from '../utils/response.js';
import { config } from '../config/env_config.js';
/*
    middleware de manejo de errores.
    Captura todos los errores no manejados y los formatea en una respuesta estandarizada.
*/
export const errorHandler = (err, req, res, next) => {
  // Si el error es una instancia de AppError, usamos sus propiedades
  if (err instanceof AppError) {
    return errorResponse(res, err.message, err.code, err.status, err.details);
  }

  // Determinar el entorno
  const isDevelopment = config.node_env === 'development';

  // Fallback para errores no manejados/inesperados
  // Para evitar exponer trazas internas en producción, proporcionamos mensajes genéricos
  const message = isDevelopment ? err.message : 'Algo salió mal';
  const code = err.code || 'INTERNAL_ERROR';
  const status = err.status || 500;
  
  // Solo exponer el stack trace en detalles si estamos en desarrollo
  const details = isDevelopment && err.stack ? [err.stack] : [];

  return errorResponse(res, message, code, status, details);
};

/*
    Middleware para manejar errores 404 Not Found para rutas no coincidentes
*/
export const notFoundHandler = (req, res, next) => {
  const error = new AppError(`No se puede encontrar ${req.originalUrl} en este servidor!`, 404, 'ROUTE_NOT_FOUND');
  next(error);
};
