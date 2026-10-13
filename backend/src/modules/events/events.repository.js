import pool from '../../database/connection.js';

// Módulos de la API que se reconocen a partir de la ruta (/api/v1/<módulo>/...).
export const KNOWN_MODULES = ['food', 'fridge', 'recipe', 'user', 'stats', 'meals', 'ai', 'admin'];
export const EVENT_MODULES = [...KNOWN_MODULES, 'chat', 'auth', 'bots', 'external', 'other'];

// Módulos que no son tráfico de la app: se ocultan juntos con hideBots.
export const NOISE_MODULES = ['bots', 'external'];

// Rutas de raíz que piden monitores, buscadores o alguien abriendo la URL de la
// API en el navegador. No se puede saber si son bots, así que van aparte.
const EXTERNAL_PATHS = ['/', '/favicon.ico', '/robots.txt', '/sitemap.xml', '/apple-touch-icon.png'];

/**
 * Deriva el módulo de un evento a partir de su ruta. Se calcula al leer para
 * que también aplique a los eventos históricos.
 *   - external: la raíz, favicon, robots.txt... (origen dudoso)
 *   - bots: el resto de rutas que no existen en la API (/.env, /wp-login.php...),
 *     que son escaneos automáticos.
 * @param {string} alias Alias de activity_events en la consulta.
 */
export const moduleSql = (alias = 'e') => `
  CASE
    WHEN ${alias}.path IS NULL THEN
      CASE WHEN ${alias}.category = 'AUTH' THEN 'auth' ELSE 'other' END
    WHEN ${alias}.path LIKE '/api/v1/n8n/%' OR ${alias}.path LIKE '/api/v1/chat%' THEN 'chat'
    WHEN split_part(${alias}.path, '/', 4) IN (${KNOWN_MODULES.map((m) => `'${m}'`).join(', ')})
      THEN split_part(${alias}.path, '/', 4)
    WHEN ${alias}.path IN (${EXTERNAL_PATHS.map((p) => `'${p}'`).join(', ')}) THEN 'external'
    ELSE 'bots'
  END
`;

/** Una consulta a la IA = un mensaje enviado al agente de n8n. */
export const aiQuerySql = (alias = 'e') =>
  `(${alias}.method = 'POST' AND ${alias}.path = '/api/v1/n8n/chat')`;

/**
 * Construye el WHERE compartido por el listado y las estadísticas.
 * @returns {{ where: string, values: Array, next: number }}
 */
const buildEventWhere = (filters = {}) => {
  const { type, category, module, userId, from, to, hideReads, hideBots } = filters;
  const conditions = [];
  const values = [];
  let i = 1;

  if (type) {
    conditions.push(`e.event_type = $${i++}`);
    values.push(type);
  }
  if (category) {
    conditions.push(`e.category = $${i++}`);
    values.push(category);
  }
  if (module) {
    conditions.push(`(${moduleSql('e')}) = $${i++}`);
    values.push(module);
  }
  if (userId !== undefined && userId !== null) {
    conditions.push(`e.user_id = $${i++}`);
    values.push(userId);
  }
  if (from) {
    conditions.push(`e.created_at >= $${i++}`);
    values.push(from);
  }
  if (to) {
    conditions.push(`e.created_at <= $${i++}`);
    values.push(to);
  }
  if (hideReads) {
    conditions.push(`(e.method IS NULL OR e.method NOT IN ('GET', 'HEAD', 'OPTIONS'))`);
  }
  if (hideBots && !NOISE_MODULES.includes(module)) {
    conditions.push(`(${moduleSql('e')}) NOT IN ('bots', 'external')`);
  }

  return {
    where: conditions.length ? `WHERE ${conditions.join(' AND ')}` : '',
    values,
    next: i,
  };
};

/**
 * Inserta un evento de actividad.
 * @param {Object} event
 * @param {string} event.eventType
 * @param {string} event.category
 * @param {number|null} [event.userId]
 * @param {string|null} [event.method]
 * @param {string|null} [event.path]
 * @param {number|null} [event.statusCode]
 * @param {string|null} [event.ip]
 * @param {Object} [event.metadata]
 * @returns {Promise<Object>}
 */
export const insertEvent = async ({
  eventType,
  category,
  userId = null,
  method = null,
  path = null,
  statusCode = null,
  ip = null,
  metadata = {},
}) => {
  const query = `
    INSERT INTO activity_events
      (event_type, category, user_id, method, path, status_code, ip_address, metadata)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)
    RETURNING
      event_id    AS "eventId",
      event_type  AS "eventType",
      category,
      user_id     AS "userId",
      method,
      path,
      status_code AS "statusCode",
      ip_address  AS "ipAddress",
      metadata,
      created_at  AS "createdAt"
  `;
  const values = [
    eventType,
    category,
    userId,
    method,
    path,
    statusCode,
    ip,
    JSON.stringify(metadata ?? {}),
  ];
  const { rows } = await pool.query(query, values);
  return rows[0];
};

/**
 * Lista eventos con filtros dinámicos y paginación.
 * @param {Object} filters
 * @param {string} [filters.type]
 * @param {string} [filters.category]
 * @param {string} [filters.module]   Ver EVENT_MODULES
 * @param {number} [filters.userId]
 * @param {string} [filters.from]  Fecha ISO
 * @param {string} [filters.to]    Fecha ISO
 * @param {boolean} [filters.hideReads] Oculta las lecturas (GET/HEAD/OPTIONS)
 * @param {boolean} [filters.hideBots]  Oculta escaneos y tráfico externo
 * @param {number} [filters.limit]
 * @param {number} [filters.offset]
 * @returns {Promise<{items: Array, total: number}>}
 */
export const findEvents = async (filters = {}) => {
  const { limit = 50, offset = 0 } = filters;
  const { where, values, next } = buildEventWhere(filters);
  let i = next;

  const countQuery = `SELECT COUNT(*)::int AS total FROM activity_events e ${where}`;
  const { rows: countRows } = await pool.query(countQuery, values);
  const total = countRows[0]?.total ?? 0;

  const listQuery = `
    SELECT
      e.event_id    AS "eventId",
      e.event_type  AS "eventType",
      e.category,
      ${moduleSql('e')} AS module,
      e.user_id     AS "userId",
      u.name        AS "userName",
      u.email       AS "userEmail",
      e.method,
      e.path,
      e.status_code AS "statusCode",
      e.ip_address  AS "ipAddress",
      e.metadata,
      e.created_at  AS "createdAt"
    FROM activity_events e
    LEFT JOIN users u ON u.user_id = e.user_id
    ${where}
    ORDER BY e.created_at DESC, e.event_id DESC
    LIMIT $${i++} OFFSET $${i++}
  `;
  const { rows } = await pool.query(listQuery, [...values, limit, offset]);

  return { items: rows, total };
};

/**
 * Agregaciones para el dashboard admin.
 * @param {Object} filters
 * @param {string} [filters.from] Fecha ISO
 * @param {string} [filters.to]   Fecha ISO
 * @returns {Promise<Object>}
 */
export const getEventStats = async (filters = {}) => {
  const { from, to, hideBots } = filters;
  const { where, values } = buildEventWhere({ from, to, hideBots });

  const byTypeQuery = `
    SELECT e.event_type AS "eventType", COUNT(*)::int AS count
    FROM activity_events e
    ${where}
    GROUP BY e.event_type
    ORDER BY count DESC
  `;

  const byCategoryQuery = `
    SELECT e.category, COUNT(*)::int AS count
    FROM activity_events e
    ${where}
    GROUP BY e.category
    ORDER BY count DESC
  `;

  const byModuleQuery = `
    SELECT ${moduleSql('e')} AS module, COUNT(*)::int AS count
    FROM activity_events e
    ${where}
    GROUP BY 1
    ORDER BY count DESC
  `;

  const byDayQuery = `
    SELECT
      to_char(date_trunc('day', e.created_at), 'YYYY-MM-DD') AS day,
      COUNT(*)::int AS count
    FROM activity_events e
    ${where}
    GROUP BY day
    ORDER BY day ASC
  `;

  const topUsersQuery = `
    SELECT e.user_id AS "userId", u.name AS "userName", COUNT(*)::int AS count
    FROM activity_events e
    LEFT JOIN users u ON u.user_id = e.user_id
    ${where ? `${where} AND e.user_id IS NOT NULL` : 'WHERE e.user_id IS NOT NULL'}
    GROUP BY e.user_id, u.name
    ORDER BY count DESC
    LIMIT 10
  `;

  const totalQuery = `SELECT COUNT(*)::int AS total FROM activity_events e ${where}`;

  const [byType, byCategory, byModule, byDay, topUsers, totalRes] = await Promise.all([
    pool.query(byTypeQuery, values),
    pool.query(byCategoryQuery, values),
    pool.query(byModuleQuery, values),
    pool.query(byDayQuery, values),
    pool.query(topUsersQuery, values),
    pool.query(totalQuery, values),
  ]);

  return {
    total: totalRes.rows[0]?.total ?? 0,
    byType: byType.rows,
    byCategory: byCategory.rows,
    byModule: byModule.rows,
    byDay: byDay.rows,
    topUsers: topUsers.rows,
  };
};

/**
 * Elimina eventos más antiguos que N días (política de retención).
 * @param {number} days
 * @param {Object} [options]
 * @param {string} [options.type] Limita el borrado a un event_type.
 * @returns {Promise<number>} Número de filas eliminadas.
 */
export const deleteEventsOlderThan = async (days, { type } = {}) => {
  const values = [days];
  let query = `
    DELETE FROM activity_events
    WHERE created_at < NOW() - ($1 * INTERVAL '1 day')
  `;
  if (type) {
    values.push(type);
    query += ` AND event_type = $2`;
  }
  const result = await pool.query(query, values);
  return result.rowCount;
};
