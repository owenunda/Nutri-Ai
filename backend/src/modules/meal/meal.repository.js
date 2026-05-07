import pool from '../../database/connection.js';

/**
 * Crea un nuevo registro de comida (encabezado) para un usuario.
 * @param {number} userId 
 * @param {string} date - Fecha en formato YYYY-MM-DD
 * @returns {Promise<Object>}
 */
export const createMealRecordRepository = async (userId, date) => {
  const query = `
    INSERT INTO meal_records (user_id, record_date)
    VALUES ($1, $2)
    RETURNING 
      meal_record_id AS "mealRecordId", 
      user_id AS "userId", 
      record_date AS "recordDate", 
      created_at AS "createdAt"
  `;
  const { rows } = await pool.query(query, [userId, date]);
  return rows[0];
};

/**
 * Añade detalles de alimentos o recetas consumidas a un registro de comida.
 * @param {number} mealRecordId 
 * @param {Array<Object>} items - [{ food_id, recipe_id, quantity }]
 * @returns {Promise<Array<Object>>}
 */
export const addItemsToMealRepository = async (mealRecordId, items) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const results = [];
    for (const item of items) {
      const { food_id, recipe_id, quantity } = item;
      const query = `
        INSERT INTO meal_record_details (meal_record_id, food_id, recipe_id, quantity)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `;
      const { rows } = await client.query(query, [mealRecordId, food_id || null, recipe_id || null, quantity]);
      results.push(rows[0]);
    }

    await client.query('COMMIT');
    return results;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Verifica si ya existe un registro de comida para un usuario en una fecha específica.
 * @param {number} userId 
 * @param {string} date 
 */
export const findMealRecordByUserAndDate = async (userId, date) => {
  const query = `
    SELECT meal_record_id AS "mealRecordId"
    FROM meal_records
    WHERE user_id = $1 AND record_date = $2
    LIMIT 1
  `;
  const { rows } = await pool.query(query, [userId, date]);
  return rows[0] || null;
};
