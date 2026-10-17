import pool from '../../database/connection.js';

/** Todos los días con vasos de un usuario, del más viejo al más nuevo. */
export const findWaterHistory = async (userId) => {
  const { rows } = await pool.query(
    `SELECT to_char(day, 'YYYY-MM-DD') AS day, glasses
       FROM water_intake
      WHERE user_id = $1
      ORDER BY day`,
    [userId]
  );
  return rows;
};

/** Suma un vaso al día (tope `goal`). Devuelve los vasos del día. */
export const addWaterGlass = async (userId, day, goal) => {
  const { rows } = await pool.query(
    `INSERT INTO water_intake (user_id, day, glasses)
     VALUES ($1, $2::date, 1)
     ON CONFLICT (user_id, day)
     DO UPDATE SET glasses = LEAST(water_intake.glasses + 1, $3), updated_at = NOW()
     RETURNING glasses`,
    [userId, day, goal]
  );
  return rows[0].glasses;
};

/**
 * Resta un vaso al día; con el último, la fila se borra. Las dos sentencias
 * ven la misma foto de la fila, así que solo una actúa.
 * @returns {Promise<number>} vasos que quedan ese día.
 */
export const undoWaterGlass = async (userId, day) => {
  const { rows } = await pool.query(
    `WITH removed AS (
       DELETE FROM water_intake
        WHERE user_id = $1 AND day = $2::date AND glasses <= 1
     )
     UPDATE water_intake
        SET glasses = glasses - 1, updated_at = NOW()
      WHERE user_id = $1 AND day = $2::date AND glasses > 1
      RETURNING glasses`,
    [userId, day]
  );
  return rows[0]?.glasses ?? 0;
};

/** Sube días del historial local; por día se queda el mayor valor. */
export const importWaterHistory = async (userId, entries) => {
  await pool.query(
    `INSERT INTO water_intake (user_id, day, glasses)
     SELECT $1, d, g FROM unnest($2::date[], $3::smallint[]) AS t(d, g)
     ON CONFLICT (user_id, day)
     DO UPDATE SET glasses = GREATEST(water_intake.glasses, EXCLUDED.glasses), updated_at = NOW()`,
    [userId, entries.map((e) => e.day), entries.map((e) => e.glasses)]
  );
};
