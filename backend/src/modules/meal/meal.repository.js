import pool from '../../database/connection.js';

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

export const addItemsToMealRepository = async (mealRecordId, items) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const results = [];
    for (const item of items) {
      const { food_id, recipe_id, quantity, meal_type } = item;
      const query = `
        INSERT INTO meal_record_details (meal_record_id, food_id, recipe_id, quantity, meal_type)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
          meal_record_detail_id AS "detailId",
          food_id AS "foodId",
          recipe_id AS "recipeId",
          quantity,
          meal_type AS "mealType"
      `;
      const { rows } = await client.query(query, [mealRecordId, food_id || null, recipe_id || null, quantity, meal_type]);
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

export const findMealRecordOwnerRepository = async (mealRecordId) => {
  const { rows } = await pool.query(
    'SELECT user_id AS "userId" FROM meal_records WHERE meal_record_id = $1',
    [mealRecordId]
  );
  return rows[0]?.userId ?? null;
};

// Solo líneas de alimentos: las de receta las crea un flujo que la app no usa.
export const getDayMealsRepository = async (userId, date) => {
  const query = `
    SELECT
      mrd.meal_record_detail_id AS "detailId",
      mrd.food_id AS "foodId",
      f.name,
      f.base_unit AS "baseUnit",
      mrd.quantity::float AS quantity,
      mrd.meal_type AS "mealType",
      mrd.meal_recipe_log_id AS "recipeLogId",
      ROUND(mrd.quantity * f.calories_per_unit)::int AS calories
    FROM meal_records mr
    JOIN meal_record_details mrd ON mrd.meal_record_id = mr.meal_record_id
    JOIN foods f ON f.food_id = mrd.food_id
    WHERE mr.user_id = $1 AND mr.record_date = $2
    ORDER BY mrd.meal_record_detail_id
  `;
  const { rows } = await pool.query(query, [userId, date]);
  return rows;
};

export const deleteMealItemRepository = async (userId, detailId) => {
  const query = `
    DELETE FROM meal_record_details mrd
    USING meal_records mr
    WHERE mrd.meal_record_detail_id = $1
      AND mr.meal_record_id = mrd.meal_record_id
      AND mr.user_id = $2
    RETURNING
      mrd.meal_record_detail_id AS "detailId",
      mrd.food_id AS "foodId",
      mrd.quantity::float AS quantity,
      mrd.meal_type AS "mealType"
  `;
  const { rows } = await pool.query(query, [detailId, userId]);
  return rows[0] ?? null;
};

// Receta del chat registrada como comida: la receta y sus ingredientes en una
// sola transacción, para no dejar ingredientes sueltos si algo falla.
export const addRecipeLogToMealRepository = async (userId, mealRecordId, { title, portions, recipe, mealType, items }) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: [log] } = await client.query(
      `INSERT INTO meal_recipe_logs (user_id, title, portions, recipe)
       VALUES ($1, $2, $3, $4)
       RETURNING meal_recipe_log_id AS "recipeLogId"`,
      [userId, title, portions, recipe]
    );
    const details = [];
    for (const item of items) {
      const { rows } = await client.query(
        `INSERT INTO meal_record_details (meal_record_id, food_id, quantity, meal_type, meal_recipe_log_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING meal_record_detail_id AS "detailId", food_id AS "foodId", quantity, meal_type AS "mealType"`,
        [mealRecordId, item.food_id, item.quantity, mealType, log.recipeLogId]
      );
      details.push(rows[0]);
    }
    await client.query('COMMIT');
    return { recipeLogId: log.recipeLogId, items: details };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

export const findRecipeLogsByIdsRepository = async (userId, ids) => {
  const { rows } = await pool.query(
    `SELECT meal_recipe_log_id AS "recipeLogId", title, portions::float AS portions, recipe
     FROM meal_recipe_logs
     WHERE user_id = $1 AND meal_recipe_log_id = ANY($2::int[])`,
    [userId, ids]
  );
  return rows;
};

// Borra la receta registrada con todos sus ingredientes, de una vez.
export const deleteRecipeLogRepository = async (userId, recipeLogId) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: [log] } = await client.query(
      `SELECT meal_recipe_log_id FROM meal_recipe_logs
       WHERE meal_recipe_log_id = $1 AND user_id = $2
       FOR UPDATE`,
      [recipeLogId, userId]
    );
    if (!log) {
      await client.query('ROLLBACK');
      return null;
    }
    const { rowCount } = await client.query(
      'DELETE FROM meal_record_details WHERE meal_recipe_log_id = $1',
      [recipeLogId]
    );
    await client.query('DELETE FROM meal_recipe_logs WHERE meal_recipe_log_id = $1', [recipeLogId]);
    await client.query('COMMIT');
    return { recipeLogId, deletedItems: rowCount };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
