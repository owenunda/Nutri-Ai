import { logEventService } from '../modules/events/events.service.js';

// Rutas que no aportan valor de auditoría (ruido / health checks / docs)
// o que se registran de forma explícita con mayor semántica (/auth).
const IGNORED_PREFIXES = ['/api/v1/health', '/api-docs', '/favicon', '/api/v1/auth'];

// No auditamos las lecturas del propio panel admin de eventos para evitar auto-ruido.
const isAdminEventsRead = (method, path) =>
  method === 'GET' && path.startsWith('/api/v1/admin/events');

/**
 * Deriva { category, eventType } a partir del método y la ruta.
 */
const classify = (method, path) => {
  if (
    path.startsWith('/api/v1/ai') ||
    path.startsWith('/api/v1/chat') ||
    path.startsWith('/api/v1/n8n')
  ) {
    return { category: 'AI', eventType: 'AI_REQUEST' };
  }
  if (method === 'POST') return { category: 'CRUD', eventType: 'CRUD_CREATE' };
  if (method === 'PUT' || method === 'PATCH') return { category: 'CRUD', eventType: 'CRUD_UPDATE' };
  if (method === 'DELETE') return { category: 'CRUD', eventType: 'CRUD_DELETE' };
  return { category: 'SYSTEM', eventType: 'HTTP_REQUEST' };
};

/**
 * Middleware global de captura automática de eventos.
 * Registra cada request relevante al finalizar la respuesta (res 'finish'),
 * sin bloquear el ciclo request/response. El logging es best-effort.
 */
export const activityLogger = (req, res, next) => {
  res.on('finish', () => {
    const path = req.originalUrl.split('?')[0];

    if (IGNORED_PREFIXES.some((prefix) => path.startsWith(prefix))) return;
    if (isAdminEventsRead(req.method, path)) return;

    // Los errores del servidor (>= 500) se registran como SYSTEM_ERROR en el errorHandler.
    if (res.statusCode >= 500) return;

    const { category, eventType } = classify(req.method, path);

    logEventService({
      eventType,
      category,
      userId: req.user?.userId ?? null,
      method: req.method,
      path,
      statusCode: res.statusCode,
      ip: req.ip,
      metadata: {},
    });
  });

  next();
};

export default activityLogger;
