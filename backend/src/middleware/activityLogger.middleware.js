import { logEventService } from '../modules/events/events.service.js';

// Rutas que no aportan valor de auditoría (ruido / health checks / docs),
// que se registran de forma explícita con mayor semántica (/auth) o que llama
// un servicio externo (el webhook de RevenueCat, que parecería un bot).
const IGNORED_PREFIXES = ['/api/v1/health', '/api-docs', '/favicon', '/api/v1/auth', '/api/v1/subscription/webhook'];

// Al terminar este request el usuario ya no existe y el insert fallaría por la
// FK; el borrado se registra de forma explícita y anónima en user.service.
const IGNORED_PATHS = ['/api/v1/user/account'];

// No auditamos las lecturas del propio panel admin para evitar auto-ruido.
const isAdminRead = (method, path) =>
  method === 'GET' && path.startsWith('/api/v1/admin');

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
    if (req.method === 'DELETE' && IGNORED_PATHS.includes(path)) return;
    if (isAdminRead(req.method, path)) return;

    // Los errores del servidor (>= 500) se registran como SYSTEM_ERROR en el errorHandler.
    if (res.statusCode >= 500) return;

    const { category, eventType } = classify(req.method, path);
    const userId = req.user?.userId ?? null;

    // En las peticiones anónimas el User-Agent ayuda a distinguir escáneres,
    // monitores y buscadores.
    const userAgent = req.get('user-agent');
    const metadata = userId === null && userAgent ? { userAgent: userAgent.slice(0, 300) } : {};

    logEventService({
      eventType,
      category,
      userId,
      method: req.method,
      path,
      statusCode: res.statusCode,
      ip: req.ip,
      metadata,
    });
  });

  next();
};

export default activityLogger;
