import { AppError } from '../utils/AppError.js';
import { errorResponse } from '../utils/response.js';
import { config } from '../config/env_config.js';
import { logEventService } from '../modules/events/events.service.js';

/*
    Registra errores del servidor (status >= 500) como SYSTEM_ERROR.
    Best-effort: logEventService nunca lanza.
*/
const logSystemError = (err, req, status, code) => {
  if (status < 500) return;
  logEventService({
    eventType: 'SYSTEM_ERROR',
    category: 'ERROR',
    userId: req.user?.userId ?? null,
    method: req.method,
    path: req.originalUrl?.split('?')[0],
    statusCode: status,
    ip: req.ip,
    metadata: {
      code,
      message: err.message,
      stack: config.node_env === 'development' ? err.stack : undefined,
    },
  });
};

/*
    middleware de manejo de errores.
    Captura todos los errores no manejados y los formatea en una respuesta estandarizada.
*/
export const errorHandler = (err, req, res, next) => {
  // Si el error es una instancia de AppError, usamos sus propiedades
  if (err instanceof AppError) {
    logSystemError(err, req, err.status, err.code);
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

  logSystemError(err, req, status, code);

  return errorResponse(res, message, code, status, details);
};

/*
    Middleware para manejar errores 404 Not Found para rutas no coincidentes
*/
export const notFoundHandler = (req, res, next) => {
  const error = new AppError(`No se puede encontrar ${req.originalUrl} en este servidor!`, 404, 'ROUTE_NOT_FOUND');
  next(error);
};
