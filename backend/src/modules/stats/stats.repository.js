import pool from '../../database/connection.js';

/**
 * Obtiene los datos nutricionales y físicos actuales del usuario.
 * @param {number} userId 
 * @returns {Promise<Object>}
 */
export const getUserNutritionalData = async (userId) => {
  const query = `
    SELECT 
      u.user_id AS "userId",
      u.age,
      u.goal,
      pr.height,
      pr.weight
    FROM users u
    LEFT JOIN LATERAL (
      SELECT height, weight
      FROM physical_records
      WHERE user_id = u.user_id
      ORDER BY record_date DESC, physical_record_id DESC
      LIMIT 1
    ) pr ON true
    WHERE u.user_id = $1
  `;
  const { rows } = await pool.query(query, [userId]);
  return rows[0];
};

/**
 * Calcula el total de calorías consumidas por el usuario en una fecha.
 * @param {number} userId
 * @param {string} date Fecha YYYY-MM-DD
 * @returns {Promise<number>}
 */
export const getConsumptionCaloriesByDate = async (userId, date) => {
  const query = `
    WITH meal_details AS (
      SELECT 
        mrd.quantity,
        mrd.food_id,
        mrd.recipe_id
      FROM meal_records mr
      JOIN meal_record_details mrd ON mr.meal_record_id = mrd.meal_record_id
      WHERE mr.user_id = $1 AND mr.record_date = $2
    ),
    food_calories AS (
      SELECT 
        md.quantity * f.calories_per_unit as calories
      FROM meal_details md
      JOIN foods f ON md.food_id = f.food_id
      WHERE md.food_id IS NOT NULL
    ),
    recipe_calories AS (
      SELECT 
        md.quantity * (
          SELECT COALESCE(SUM(ri.quantity * f.calories_per_unit), 0)
          FROM recipe_ingredients ri
          JOIN foods f ON ri.food_id = f.food_id
          WHERE ri.recipe_id = md.recipe_id
        ) as calories
      FROM meal_details md
      WHERE md.recipe_id IS NOT NULL
    )
    SELECT 
      COALESCE(SUM(calories), 0) as total_calories
    FROM (
      SELECT calories FROM food_calories
      UNION ALL
      SELECT calories FROM recipe_calories
    ) combined_calories
  `;
  
  const { rows } = await pool.query(query, [userId, date]);
  return parseFloat(rows[0]?.total_calories || 0);
};

/**
 * Calorías consumidas por día en un rango (una fila por día, con 0 si no hay registros).
 * @param {number} userId
 * @param {string} start Fecha YYYY-MM-DD
 * @param {string} end Fecha YYYY-MM-DD
 * @returns {Promise<Array<{date: string, totalConsumed: number}>>}
 */
export const getWeekConsumptionRepository = async (userId, start, end) => {
  const query = `
    WITH days AS (
      SELECT generate_series($2::date, $3::date, '1 day')::date AS day
    ),
    food_cal AS (
      SELECT mr.record_date AS day, SUM(mrd.quantity * f.calories_per_unit) AS calories
      FROM meal_records mr
      JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
      JOIN foods f ON f.food_id = mrd.food_id
      WHERE mr.user_id = $1 AND mr.record_date BETWEEN $2 AND $3
      GROUP BY mr.record_date
    ),
    recipe_cal AS (
      SELECT mr.record_date AS day,
             SUM(mrd.quantity * (
               SELECT COALESCE(SUM(ri.quantity * f.calories_per_unit), 0)
               FROM recipe_ingredients ri
               JOIN foods f ON ri.food_id = f.food_id
               WHERE ri.recipe_id = mrd.recipe_id
             )) AS calories
      FROM meal_records mr
      JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
      WHERE mr.user_id = $1 AND mr.record_date BETWEEN $2 AND $3
        AND mrd.recipe_id IS NOT NULL
      GROUP BY mr.record_date
    )
    SELECT to_char(d.day, 'YYYY-MM-DD') AS date,
           (COALESCE(fc.calories, 0) + COALESCE(rc.calories, 0))::float AS total
    FROM days d
    LEFT JOIN food_cal fc ON fc.day = d.day
    LEFT JOIN recipe_cal rc ON rc.day = d.day
    ORDER BY d.day
  `;
  const { rows } = await pool.query(query, [userId, start, end]);
  return rows.map((r) => ({ date: r.date, totalConsumed: Math.round(r.total) }));
};
