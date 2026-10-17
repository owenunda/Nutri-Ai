import pool from '../../database/connection.js';

/**
 * Nombre del plan del usuario (FREE / PRO), o null si el usuario no existe.
 * Un PRO regalado que ya venció cuenta como FREE aunque el barrido no haya pasado.
 */
export const findUserPlanById = async (userId) => {
  const { rows } = await pool.query(
    `SELECT CASE
              WHEN p.name = 'PRO' AND u.pro_until IS NOT NULL AND u.pro_until <= NOW() THEN 'FREE'
              ELSE p.name
            END AS plan
       FROM users u
       INNER JOIN plans p ON p.plan_id = u.plan_id
      WHERE u.user_id = $1`,
    [userId]
  );
  return rows[0]?.plan ?? null;
};
