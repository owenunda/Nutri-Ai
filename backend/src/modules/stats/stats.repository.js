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
 * Calcula el total de calorías consumidas por el usuario en el día actual.
 * @param {number} userId 
 * @returns {Promise<number>}
 */
export const getTodayConsumptionCalories = async (userId) => {
  const today = new Date().toISOString().split('T')[0];

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
  
  const { rows } = await pool.query(query, [userId, today]);
  return parseFloat(rows[0]?.total_calories || 0);
};
