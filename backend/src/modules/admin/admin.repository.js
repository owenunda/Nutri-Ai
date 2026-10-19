import pool from '../../database/connection.js';
import { moduleSql, aiQuerySql } from '../events/events.repository.js';
import { DAILY_GOAL } from '../hydration/waterStreak.js';
import { STORE_RENEWAL_WAIT_MS } from '../subscription/effectivePlan.js';

// Las fechas se guardan como TIMESTAMP sin zona (UTC del servidor). Las series
// por día del panel se agrupan en la zona horaria de quien lo usa.
export const PANEL_TIMEZONE = 'America/Bogota';

const localDay = (column) => `((${column}) AT TIME ZONE 'UTC' AT TIME ZONE $2::text)::date`;

// Los invitados de la beta no cuentan como usuarios en los totales del overview.
// NOT IN con una subconsulta sin correlación: Postgres la resuelve una vez
// (hashed subplan) en vez de una por fila. users.user_id es PK y no nulo, así
// que el NOT IN no se anula por NULLs; un user_id NULL del lado izquierdo
// simplemente no cuenta (igual que en COUNT(DISTINCT)).
const notGuestSql = (alias) =>
  `${alias}.user_id NOT IN (SELECT user_id FROM users WHERE guest_expires_at IS NOT NULL)`;

// Kcal por usuario y día, con la misma cuenta que /stats: alimentos más los
// ingredientes de las recetas. `where` filtra meal_records (alias mr).
const dailyCaloriesSql = (where) => `
  SELECT
    mr.user_id,
    mr.record_date AS day,
    SUM(
      COALESCE(mrd.quantity * f.calories_per_unit, 0)
      + COALESCE(mrd.quantity * (
          SELECT COALESCE(SUM(ri.quantity * rf.calories_per_unit), 0)
          FROM recipe_ingredients ri
          INNER JOIN foods rf ON rf.food_id = ri.food_id
          WHERE ri.recipe_id = mrd.recipe_id
        ), 0)
    ) AS calories
  FROM meal_records mr
  INNER JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
  LEFT JOIN foods f ON f.food_id = mrd.food_id
  WHERE ${where}
  GROUP BY mr.user_id, mr.record_date
`;

/**
 * Resumen general del panel: usuarios, actividad, IA y series por día.
 * @param {number} days Rango (en días) para las series y los totales "del periodo".
 * @param {string} today 'YYYY-MM-DD' en PANEL_TIMEZONE, para los días del agua.
 */
export const getOverview = async (days, today) => {
  const rangeValues = [days];
  const seriesValues = [days, PANEL_TIMEZONE];
  const inRange = (column) => `${column} >= NOW() - ($1::int * INTERVAL '1 day')`;

  // Los invitados de la beta no cuentan como usuarios.
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
    WHERE u.guest_expires_at IS NULL
  `;

  const activityQuery = `
    SELECT
      COUNT(DISTINCT e.user_id) FILTER (WHERE e.created_at >= NOW() - INTERVAL '1 day' AND ${notGuestSql('e')})::int AS "active24h",
      COUNT(DISTINCT e.user_id) FILTER (WHERE e.created_at >= NOW() - INTERVAL '7 days' AND ${notGuestSql('e')})::int AS "active7d",
      COUNT(DISTINCT e.user_id) FILTER (WHERE ${inRange('e.created_at')} AND ${notGuestSql('e')})::int AS "activeInRange",
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
      (SELECT COUNT(*)
         FROM meal_record_details d
         JOIN meal_records r ON r.meal_record_id = d.meal_record_id
         WHERE r.user_id NOT IN (SELECT user_id FROM users WHERE guest_expires_at IS NOT NULL))::int AS "mealItems",
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
        COUNT(DISTINCT e.user_id) FILTER (WHERE ${notGuestSql('e')}) AS active,
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
        AND u.guest_expires_at IS NULL
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
    WHERE ${aiQuerySql('e')} AND ${inRange('e.created_at')} AND u.guest_expires_at IS NULL
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
    WHERE u.guest_expires_at IS NULL
    ORDER BY u.created_at DESC, u.user_id DESC
    LIMIT 6
  `;

  // Los días del agua son fechas locales que manda la app, no timestamps.
  const waterQuery = `
    SELECT
      COUNT(DISTINCT w.user_id)::int AS users,
      COUNT(DISTINCT w.user_id) FILTER (WHERE w.day > $2::date - 7)::int AS "users7d",
      COUNT(DISTINCT w.user_id) FILTER (WHERE w.day > $2::date - $1::int)::int AS "usersInRange",
      COUNT(*) FILTER (WHERE w.day > $2::date - $1::int)::int AS "daysInRange",
      COUNT(*) FILTER (WHERE w.day > $2::date - $1::int AND w.glasses >= $3)::int AS "goalDaysInRange",
      COALESCE(SUM(w.glasses) FILTER (WHERE w.day > $2::date - $1::int), 0)::int AS "glassesInRange"
    FROM water_intake w
    WHERE ${notGuestSql('w')}
  `;

  // Historial de quien cumplió la meta hoy o ayer: los únicos que pueden
  // tener una racha viva. La racha se calcula en el servicio.
  const waterStreakRowsQuery = `
    SELECT
      w.user_id AS "userId",
      u.name,
      p.name AS plan,
      to_char(w.day, 'YYYY-MM-DD') AS day,
      w.glasses
    FROM water_intake w
    INNER JOIN users u ON u.user_id = w.user_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    WHERE u.guest_expires_at IS NULL
      AND w.user_id IN (
        SELECT user_id FROM water_intake WHERE glasses >= $2 AND day >= $1::date - 1
      )
    ORDER BY w.user_id, w.day
  `;

  // Kcal por día de quien registró comida hoy o ayer (los únicos con una racha
  // calórica viva), con edad, objetivo, altura y peso para su meta. Basta con
  // el último año: una racha más larga se vería cortada a 400 días.
  const calorieStreakRowsQuery = `
    SELECT
      u.user_id AS "userId",
      u.name,
      p.name AS plan,
      u.age,
      u.goal,
      pr.height,
      pr.weight,
      to_char(dc.day, 'YYYY-MM-DD') AS day,
      dc.calories::float AS calories
    FROM (${dailyCaloriesSql(`mr.record_date >= $1::date - 400
      AND mr.user_id IN (SELECT user_id FROM meal_records WHERE record_date >= $1::date - 1)`)}) dc
    INNER JOIN users u ON u.user_id = dc.user_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    LEFT JOIN LATERAL (
      SELECT height, weight
      FROM physical_records
      WHERE user_id = u.user_id
      ORDER BY record_date DESC, physical_record_id DESC
      LIMIT 1
    ) pr ON true
    WHERE u.guest_expires_at IS NULL
    ORDER BY u.user_id, dc.day
  `;

  const waterValues = [days, today, DAILY_GOAL];
  const [
    users, activity, content, series, byModule, topAiUsers, recentUsers, water, waterStreakRows, calorieStreakRows,
  ] = await Promise.all([
    pool.query(usersQuery, rangeValues),
    pool.query(activityQuery, rangeValues),
    pool.query(contentQuery),
    pool.query(seriesQuery, seriesValues),
    pool.query(byModuleQuery, rangeValues),
    pool.query(topAiUsersQuery, rangeValues),
    pool.query(recentUsersQuery),
    pool.query(waterQuery, waterValues),
    pool.query(waterStreakRowsQuery, [today, DAILY_GOAL]),
    pool.query(calorieStreakRowsQuery, [today]),
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
    water: water.rows[0],
    waterStreakRows: waterStreakRows.rows,
    calorieStreakRows: calorieStreakRows.rows,
  };
};

const USER_SORTS = {
  recent: 'u.created_at DESC, u.user_id DESC',
  ai: '"aiQueries" DESC, u.user_id DESC',
  activity: '"lastActivity" DESC NULLS LAST, u.user_id DESC',
  name: 'u.name ASC, u.user_id ASC',
};
export const USER_SORT_KEYS = Object.keys(USER_SORTS);

// Cómo entra el usuario: invitado, solo contraseña, solo Google, o ambos.
const authMethodSql = (alias) => `
  CASE
    WHEN ${alias}.guest_expires_at IS NOT NULL THEN 'GUEST'
    WHEN ${alias}.password IS NULL THEN 'GOOGLE'
    WHEN EXISTS (
      SELECT 1 FROM user_auth_providers ap WHERE ap.user_id = ${alias}.user_id
    ) THEN 'BOTH'
    ELSE 'EMAIL'
  END`;

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
      u.pro_until AS "proUntil",
      ${authMethodSql('u')} AS "authMethod",
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
      u.pro_until AS "proUntil",
      u.gift_pro AS "giftPro",
      u.gift_pro_until AS "giftProUntil",
      CASE WHEN ss.user_id IS NULL THEN NULL ELSE json_build_object(
        'productId', ss.product_id,
        'store', ss.store,
        'expiresAt', ss.expires_at,
        'willRenew', ss.will_renew,
        'billingIssue', ss.billing_issue,
        'environment', ss.environment
      ) END AS subscription,
      ${authMethodSql('u')} AS "authMethod",
      pr.height,
      pr.weight,
      u.created_at AS "createdAt",
      u.updated_at AS "updatedAt"
    FROM users u
    INNER JOIN roles r ON r.role_id = u.role_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    LEFT JOIN store_subscriptions ss ON ss.user_id = u.user_id
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

  const waterQuery = `
    SELECT to_char(day, 'YYYY-MM-DD') AS day, glasses
    FROM water_intake
    WHERE user_id = $1
    ORDER BY day
  `;

  const caloriesQuery = `
    SELECT to_char(dc.day, 'YYYY-MM-DD') AS day, dc.calories::float AS calories
    FROM (${dailyCaloriesSql('mr.user_id = $1')}) dc
    ORDER BY dc.day
  `;

  const values = [userId, PANEL_TIMEZONE];
  const [usage, series, byModule, recentEvents, water, calories] = await Promise.all([
    pool.query(usageQuery, values),
    pool.query(seriesQuery, values),
    pool.query(byModuleQuery, [userId]),
    pool.query(recentEventsQuery, [userId]),
    pool.query(waterQuery, [userId]),
    pool.query(caloriesQuery, [userId]),
  ]);

  return {
    profile,
    usage: usage.rows[0],
    series: series.rows,
    byModule: byModule.rows,
    recentEvents: recentEvents.rows,
    waterRows: water.rows,
    calorieRows: calories.rows,
  };
};

/**
 * Pasa a FREE a quien tenía PRO con fecha y ya venció. No baja a quien iba a
 * renovar en la tienda mientras RevenueCat no lo confirme (hasta
 * STORE_RENEWAL_WAIT_MS después de expires_at): su sync ya lo pone al día.
 * @returns {Promise<number[]>} ids de los usuarios que volvieron a FREE.
 */
export const expireGiftedPro = async () => {
  const { rows } = await pool.query(
    `UPDATE users u
        SET plan_id = (SELECT plan_id FROM plans WHERE name = 'FREE'),
            pro_until = NULL,
            updated_at = CURRENT_TIMESTAMP
      WHERE u.pro_until IS NOT NULL AND u.pro_until <= NOW()
        AND NOT EXISTS (
          SELECT 1 FROM store_subscriptions ss
           WHERE ss.user_id = u.user_id
             AND ss.will_renew = TRUE
             AND ss.expires_at > NOW() - ($1::bigint * INTERVAL '1 millisecond')
        )
      RETURNING u.user_id AS "userId"`,
    [STORE_RENEWAL_WAIT_MS]
  );
  return rows.map((row) => row.userId);
};

/**
 * Pone una contraseña nueva (ya hasheada) a un usuario.
 * @returns {Promise<Object|null>} { userId } o null si no existe.
 */
export const updateUserPassword = async (userId, passwordHash) => {
  const { rows } = await pool.query(
    `UPDATE users SET password = $2, updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1
     RETURNING user_id AS "userId"`,
    [userId, passwordHash]
  );
  return rows[0] ?? null;
};

/**
 * Cambia el rol de un usuario (ADMIN / USER).
 * @returns {Promise<Object|null>} El usuario actualizado o null si no existe.
 */
export const updateUserRole = async (userId, roleName) => {
  const query = `
    UPDATE users u
    SET role_id = r.role_id, updated_at = CURRENT_TIMESTAMP
    FROM roles r
    WHERE u.user_id = $1 AND r.name = $2
    RETURNING u.user_id AS "userId", r.name AS role
  `;
  const { rows } = await pool.query(query, [userId, roleName]);
  return rows[0] ?? null;
};
