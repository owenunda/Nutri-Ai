import pool from '../../database/connection.js';

export const findUserProfileById = async (userId) => {
  const query = `
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      u.goal,
      r.name AS role,
      p.name AS plan,
      u.created_at AS "createdAt",
      u.updated_at AS "updatedAt"
    FROM users u
    INNER JOIN roles r ON r.role_id = u.role_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    WHERE u.user_id = $1
    LIMIT 1
  `;

  const { rows } = await pool.query(query, [userId]);
  return rows[0] ?? null;
};
