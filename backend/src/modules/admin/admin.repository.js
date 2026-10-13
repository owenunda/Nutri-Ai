import pool from '../../database/connection.js';
import { moduleSql, aiQuerySql } from '../events/events.repository.js';

// Las fechas se guardan como TIMESTAMP sin zona (UTC del servidor). Las series
// por día del panel se agrupan en la zona horaria de quien lo usa.
const PANEL_TIMEZONE = 'America/Bogota';

const localDay = (column) => `((${column}) AT TIME ZONE 'UTC' AT TIME ZONE $2::text)::date`;

/**
 * Resumen general del panel: usuarios, actividad, IA y series por día.
 * @param {number} days Rango (en días) para las series y los totales "del periodo".
 */
export const getOverview = async (days) => {
  const rangeValues = [days];
  const seriesValues = [days, PANEL_TIMEZONE];
  const inRange = (column) => `${column} >= NOW() - ($1::int * INTERVAL '1 day')`;

  const usersQuery = `
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE u.created_at >= NOW() - INTERVAL '7 days')::int AS "new7d",
      COUNT(*) FILTER (WHERE ${inRange('u.created_at')})::int AS "newInRange",
      COUNT(*) FILTER (WHERE p.name = 'PRO')::int AS pro,
      COUNT(*) FILTER (WHERE r.name = 'ADMIN')::int AS admins
    FROM users u
    INNER JOIN plans p ON p.plan_id = u.plan_id
    INNER JOIN roles r ON r.role_id = u.role_id
  `;

  const activityQuery = `
    SELECT
      COUNT(DISTINCT e.user_id) FILTER (WHERE e.created_at >= NOW() - INTERVAL '1 day')::int AS "active24h",
      COUNT(DISTINCT e.user_id) FILTER (WHERE e.created_at >= NOW() - INTERVAL '7 days')::int AS "active7d",
      COUNT(DISTINCT e.user_id) FILTER (WHERE ${inRange('e.created_at')})::int AS "activeInRange",
      COUNT(*) FILTER (WHERE ${aiQuerySql('e')})::int AS "aiQueriesTotal",
      COUNT(*) FILTER (WHERE ${aiQuerySql('e')} AND e.created_at >= NOW() - INTERVAL '1 day')::int AS "aiQueries24h",
      COUNT(*) FILTER (WHERE ${aiQuerySql('e')} AND ${inRange('e.created_at')})::int AS "aiQueriesInRange",
      COUNT(*) FILTER (WHERE e.category = 'ERROR' AND e.created_at >= NOW() - INTERVAL '1 day')::int AS "errors24h",
      COUNT(*) FILTER (WHERE e.category = 'ERROR' AND ${inRange('e.created_at')})::int AS "errorsInRange",
      COUNT(*) FILTER (WHERE e.event_type = 'LOGIN_FAILED' AND ${inRange('e.created_at')})::int AS "failedLoginsInRange",
      COUNT(*) FILTER (WHERE (${moduleSql('e')}) = 'bots' AND ${inRange('e.created_at')})::int AS "botHitsInRange",
      COUNT(*) FILTER (WHERE (${moduleSql('e')}) = 'external' AND ${inRange('e.created_at')})::int AS "externalHitsInRange",
      COUNT(*) FILTER (WHERE (${moduleSql('e')}) NOT IN ('bots', 'external') AND ${inRange('e.created_at')})::int AS "apiRequestsInRange"
    FROM activity_events e
  `;

  const contentQuery = `
    SELECT
      (SELECT COUNT(*) FROM meal_recipe_logs)::int AS "recipesSaved",
      (SELECT COUNT(*) FROM meal_record_details)::int AS "mealItems",
      (SELECT COUNT(*) FROM chat_sessions)::int AS "chatSessions",
      (SELECT COUNT(*) FROM chat_messages WHERE role = 'USER')::int AS "chatMessages",
      (SELECT COUNT(*) FROM foods WHERE is_global = FALSE)::int AS "customFoods"
  `;

  const seriesQuery = `
    WITH days AS (
      SELECT generate_series(
        ((NOW() AT TIME ZONE $2::text)::date - ($1::int - 1))::timestamp,
        (NOW() AT TIME ZONE $2::text)::date::timestamp,
        INTERVAL '1 day'
      )::date AS day
    ),
    ev AS (
      SELECT
        ${localDay('e.created_at')} AS day,
        COUNT(*) FILTER (WHERE ${aiQuerySql('e')}) AS ai,
        COUNT(DISTINCT e.user_id) AS active,
        COUNT(*) FILTER (WHERE (${moduleSql('e')}) NOT IN ('bots', 'external')) AS requests,
        COUNT(*) FILTER (WHERE (${moduleSql('e')}) IN ('bots', 'external')) AS bots
      FROM activity_events e
      WHERE e.created_at >= NOW() - (($1::int + 1) * INTERVAL '1 day')
      GROUP BY 1
    ),
    reg AS (
      SELECT ${localDay('u.created_at')} AS day, COUNT(*) AS n
      FROM users u
      WHERE u.created_at >= NOW() - (($1::int + 1) * INTERVAL '1 day')
      GROUP BY 1
    )
    SELECT
      to_char(d.day, 'YYYY-MM-DD') AS day,
      COALESCE(reg.n, 0)::int AS registrations,
      COALESCE(ev.ai, 0)::int AS "aiQueries",
      COALESCE(ev.active, 0)::int AS "activeUsers",
      COALESCE(ev.requests, 0)::int AS requests,
      COALESCE(ev.bots, 0)::int AS bots
    FROM days d
    LEFT JOIN ev ON ev.day = d.day
    LEFT JOIN reg ON reg.day = d.day
    ORDER BY d.day
  `;

  const byModuleQuery = `
    SELECT ${moduleSql('e')} AS module, COUNT(*)::int AS count
    FROM activity_events e
    WHERE ${inRange('e.created_at')}
    GROUP BY 1
    ORDER BY count DESC
  `;

  const topAiUsersQuery = `
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      p.name AS plan,
      COUNT(*)::int AS "aiQueries"
    FROM activity_events e
    INNER JOIN users u ON u.user_id = e.user_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    WHERE ${aiQuerySql('e')} AND ${inRange('e.created_at')}
    GROUP BY u.user_id, u.name, u.email, p.name
    ORDER BY "aiQueries" DESC
    LIMIT 8
  `;

  const recentUsersQuery = `
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      p.name AS plan,
      u.goal,
      u.created_at AS "createdAt"
    FROM users u
    INNER JOIN plans p ON p.plan_id = u.plan_id
    ORDER BY u.created_at DESC, u.user_id DESC
    LIMIT 6
  `;

  const [users, activity, content, series, byModule, topAiUsers, recentUsers] = await Promise.all([
    pool.query(usersQuery, rangeValues),
    pool.query(activityQuery, rangeValues),
    pool.query(contentQuery),
    pool.query(seriesQuery, seriesValues),
    pool.query(byModuleQuery, rangeValues),
    pool.query(topAiUsersQuery, rangeValues),
    pool.query(recentUsersQuery),
  ]);

  return {
    days,
    users: users.rows[0],
    activity: activity.rows[0],
    content: content.rows[0],
    series: series.rows,
    byModule: byModule.rows,
    topAiUsers: topAiUsers.rows,
    recentUsers: recentUsers.rows,
  };
};

const USER_SORTS = {
  recent: 'u.created_at DESC, u.user_id DESC',
  ai: '"aiQueries" DESC, u.user_id DESC',
  activity: '"lastActivity" DESC NULLS LAST, u.user_id DESC',
  name: 'u.name ASC, u.user_id ASC',
};
export const USER_SORT_KEYS = Object.keys(USER_SORTS);

/**
 * Lista usuarios con su uso de la app y de la IA.
 * @param {Object} filters
 * @param {string} [filters.search] Nombre, correo o id
 * @param {string} [filters.plan]   FREE | PRO
 * @param {string} [filters.sort]   Ver USER_SORT_KEYS
 * @param {number} filters.limit
 * @param {number} filters.offset
 */
export const findUsers = async ({ search, plan, sort = 'recent', limit, offset }) => {
  const conditions = [];
  const values = [];
  let i = 1;

  if (search) {
    const idCondition = /^\d+$/.test(search) ? ` OR u.user_id = $${i + 1}` : '';
    conditions.push(`(u.name ILIKE $${i} OR u.email ILIKE $${i}${idCondition})`);
    values.push(`%${search}%`);
    i++;
    if (idCondition) {
      values.push(Number(search));
      i++;
    }
  }
  if (plan) {
    conditions.push(`p.name = $${i++}`);
    values.push(plan);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const query = `
    WITH ev AS (
      SELECT
        e.user_id,
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE ${aiQuerySql('e')})::int AS ai,
        COUNT(*) FILTER (WHERE ${aiQuerySql('e')} AND e.created_at >= NOW() - INTERVAL '7 days')::int AS ai7d,
        MAX(e.created_at) AS last_activity
      FROM activity_events e
      WHERE e.user_id IS NOT NULL
      GROUP BY e.user_id
    )
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      u.age,
      u.goal,
      r.name AS role,
      p.name AS plan,
      u.created_at AS "createdAt",
      COALESCE(ev.total, 0) AS "totalEvents",
      COALESCE(ev.ai, 0) AS "aiQueries",
      COALESCE(ev.ai7d, 0) AS "aiQueries7d",
      ev.last_activity AS "lastActivity",
      (SELECT COUNT(*) FROM meal_record_details d
         INNER JOIN meal_records m ON m.meal_record_id = d.meal_record_id
        WHERE m.user_id = u.user_id)::int AS "mealItems",
      (SELECT COUNT(*) FROM meal_recipe_logs l WHERE l.user_id = u.user_id)::int AS "recipesSaved",
      COUNT(*) OVER()::int AS "totalCount"
    FROM users u
    INNER JOIN roles r ON r.role_id = u.role_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    LEFT JOIN ev ON ev.user_id = u.user_id
    ${where}
    ORDER BY ${USER_SORTS[sort] ?? USER_SORTS.recent}
    LIMIT $${i++} OFFSET $${i++}
  `;

  const { rows } = await pool.query(query, [...values, limit, offset]);
  const total = rows[0]?.totalCount ?? 0;
  return { total, items: rows.map(({ totalCount, ...row }) => row) };
};

/**
 * Detalle de un usuario: perfil, métricas de uso y actividad reciente.
 * @param {number} userId
 * @returns {Promise<Object|null>}
 */
export const findUserDetail = async (userId) => {
  const profileQuery = `
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      u.age,
      u.goal,
      r.name AS role,
      p.name AS plan,
      pr.height,
      pr.weight,
      u.created_at AS "createdAt",
      u.updated_at AS "updatedAt"
    FROM users u
    INNER JOIN roles r ON r.role_id = u.role_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    LEFT JOIN LATERAL (
      SELECT height, weight
      FROM physical_records
      WHERE user_id = u.user_id
      ORDER BY record_date DESC, physical_record_id DESC
      LIMIT 1
    ) pr ON true
    WHERE u.user_id = $1
  `;

  const { rows: profileRows } = await pool.query(profileQuery, [userId]);
  const profile = profileRows[0];
  if (!profile) return null;

  const usageQuery = `
    SELECT
      COUNT(*)::int AS "totalEvents",
      COUNT(*) FILTER (WHERE ${aiQuerySql('e')})::int AS "aiQueries",
      COUNT(*) FILTER (WHERE ${aiQuerySql('e')} AND e.created_at >= NOW() - INTERVAL '7 days')::int AS "aiQueries7d",
      COUNT(*) FILTER (WHERE e.event_type = 'LOGIN')::int AS logins,
      COUNT(*) FILTER (WHERE e.category = 'ERROR')::int AS errors,
      MAX(e.created_at) FILTER (WHERE e.event_type = 'LOGIN') AS "lastLogin",
      MAX(e.created_at) AS "lastActivity",
      COUNT(DISTINCT ${localDay('e.created_at')})::int AS "activeDays",
      (SELECT COUNT(*) FROM chat_sessions s WHERE s.user_id = $1)::int AS "chatSessions",
      (SELECT COUNT(*) FROM chat_messages cm
         INNER JOIN chat_sessions s ON s.session_id = cm.session_id
        WHERE s.user_id = $1 AND cm.role = 'USER')::int AS "chatMessages",
      (SELECT COUNT(*) FROM meal_records m WHERE m.user_id = $1)::int AS "mealDays",
      (SELECT COUNT(*) FROM meal_record_details d
         INNER JOIN meal_records m ON m.meal_record_id = d.meal_record_id
        WHERE m.user_id = $1)::int AS "mealItems",
      (SELECT COUNT(*) FROM meal_recipe_logs l WHERE l.user_id = $1)::int AS "recipesSaved",
      (SELECT COUNT(*) FROM fridge_items fi
         INNER JOIN fridges f ON f.fridge_id = fi.fridge_id
        WHERE f.user_id = $1)::int AS "fridgeItems",
      (SELECT COUNT(*) FROM foods fo WHERE fo.created_by_user_id = $1)::int AS "customFoods",
      (SELECT COUNT(*) FROM physical_records ph WHERE ph.user_id = $1)::int AS "weighIns"
    FROM activity_events e
    WHERE e.user_id = $1
  `;

  const seriesQuery = `
    WITH days AS (
      SELECT generate_series(
        ((NOW() AT TIME ZONE $2::text)::date - 29)::timestamp,
        (NOW() AT TIME ZONE $2::text)::date::timestamp,
        INTERVAL '1 day'
      )::date AS day
    ),
    ev AS (
      SELECT
        ${localDay('e.created_at')} AS day,
        COUNT(*) AS total,
        COUNT(*) FILTER (WHERE ${aiQuerySql('e')}) AS ai
      FROM activity_events e
      WHERE e.user_id = $1 AND e.created_at >= NOW() - INTERVAL '31 days'
      GROUP BY 1
    )
    SELECT
      to_char(d.day, 'YYYY-MM-DD') AS day,
      COALESCE(ev.total, 0)::int AS events,
      COALESCE(ev.ai, 0)::int AS "aiQueries"
    FROM days d
    LEFT JOIN ev ON ev.day = d.day
    ORDER BY d.day
  `;

  const byModuleQuery = `
    SELECT ${moduleSql('e')} AS module, COUNT(*)::int AS count
    FROM activity_events e
    WHERE e.user_id = $1
    GROUP BY 1
    ORDER BY count DESC
  `;

  const recentEventsQuery = `
    SELECT
      e.event_id    AS "eventId",
      e.event_type  AS "eventType",
      e.category,
      ${moduleSql('e')} AS module,
      e.method,
      e.path,
      e.status_code AS "statusCode",
      e.created_at  AS "createdAt"
    FROM activity_events e
    WHERE e.user_id = $1
    ORDER BY e.created_at DESC, e.event_id DESC
    LIMIT 25
  `;

  const values = [userId, PANEL_TIMEZONE];
  const [usage, series, byModule, recentEvents] = await Promise.all([
    pool.query(usageQuery, values),
    pool.query(seriesQuery, values),
    pool.query(byModuleQuery, [userId]),
    pool.query(recentEventsQuery, [userId]),
  ]);

  return {
    profile,
    usage: usage.rows[0],
    series: series.rows,
    byModule: byModule.rows,
    recentEvents: recentEvents.rows,
  };
};

/**
 * Cambia el plan de un usuario.
 * @returns {Promise<Object|null>} El usuario actualizado o null si no existe.
 */
export const updateUserPlan = async (userId, planName) => {
  const query = `
    UPDATE users u
    SET plan_id = p.plan_id, updated_at = CURRENT_TIMESTAMP
    FROM plans p
    WHERE u.user_id = $1 AND p.name = $2
    RETURNING u.user_id AS "userId", p.name AS plan
  `;
  const { rows } = await pool.query(query, [userId, planName]);
  return rows[0] ?? null;
};
