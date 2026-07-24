import pool from '../../database/connection.js';

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
 * @param {number} [filters.userId]
 * @param {string} [filters.from]  Fecha ISO
 * @param {string} [filters.to]    Fecha ISO
 * @param {number} [filters.limit]
 * @param {number} [filters.offset]
 * @returns {Promise<{items: Array, total: number}>}
 */
export const findEvents = async (filters = {}) => {
  const { type, category, userId, from, to, limit = 50, offset = 0 } = filters;

  const conditions = [];
  const values = [];
  let i = 1;

  if (type) {
    conditions.push(`event_type = $${i++}`);
    values.push(type);
  }
  if (category) {
    conditions.push(`category = $${i++}`);
    values.push(category);
  }
  if (userId !== undefined && userId !== null) {
    conditions.push(`user_id = $${i++}`);
    values.push(userId);
  }
  if (from) {
    conditions.push(`created_at >= $${i++}`);
    values.push(from);
  }
  if (to) {
    conditions.push(`created_at <= $${i++}`);
    values.push(to);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countQuery = `SELECT COUNT(*)::int AS total FROM activity_events ${where}`;
  const { rows: countRows } = await pool.query(countQuery, values);
  const total = countRows[0]?.total ?? 0;

  const listQuery = `
    SELECT
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
    FROM activity_events
    ${where}
    ORDER BY created_at DESC, event_id DESC
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
  const { from, to } = filters;

  const conditions = [];
  const values = [];
  let i = 1;

  if (from) {
    conditions.push(`created_at >= $${i++}`);
    values.push(from);
  }
  if (to) {
    conditions.push(`created_at <= $${i++}`);
    values.push(to);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const byTypeQuery = `
    SELECT event_type AS "eventType", COUNT(*)::int AS count
    FROM activity_events
    ${where}
    GROUP BY event_type
    ORDER BY count DESC
  `;

  const byCategoryQuery = `
    SELECT category, COUNT(*)::int AS count
    FROM activity_events
    ${where}
    GROUP BY category
    ORDER BY count DESC
  `;

  const byDayQuery = `
    SELECT
      to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day,
      COUNT(*)::int AS count
    FROM activity_events
    ${where}
    GROUP BY day
    ORDER BY day ASC
  `;

  const topUsersQuery = `
    SELECT user_id AS "userId", COUNT(*)::int AS count
    FROM activity_events
    ${where ? `${where} AND user_id IS NOT NULL` : 'WHERE user_id IS NOT NULL'}
    GROUP BY user_id
    ORDER BY count DESC
    LIMIT 10
  `;

  const totalQuery = `SELECT COUNT(*)::int AS total FROM activity_events ${where}`;

  const [byType, byCategory, byDay, topUsers, totalRes] = await Promise.all([
    pool.query(byTypeQuery, values),
    pool.query(byCategoryQuery, values),
    pool.query(byDayQuery, values),
    pool.query(topUsersQuery, values),
    pool.query(totalQuery, values),
  ]);

  return {
    total: totalRes.rows[0]?.total ?? 0,
    byType: byType.rows,
    byCategory: byCategory.rows,
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
