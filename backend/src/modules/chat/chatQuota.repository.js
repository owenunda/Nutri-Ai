import pool from '../../database/connection.js';

/** Nombre del plan del usuario (FREE / PRO), o null si el usuario no existe. */
export const findUserPlanById = async (userId) => {
  const { rows } = await pool.query(
    `SELECT p.name AS plan
       FROM users u
       INNER JOIN plans p ON p.plan_id = u.plan_id
      WHERE u.user_id = $1`,
    [userId]
  );
  return rows[0]?.plan ?? null;
};
