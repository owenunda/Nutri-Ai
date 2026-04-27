import pool from '../../database/conection.js';

export const getAuthRepositoryStatus = async () => {
  return {
    layer: 'repository',
    status: 'ready',
  };
};

export const findUserByEmail = async (email) => {
  const query = `
    SELECT
      u.user_id AS "userId",
      u.name,
      u.email,
      u.password AS "passwordHash",
      u.goal,
      r.name AS role,
      p.name AS plan,
      u.created_at AS "createdAt",
      u.updated_at AS "updatedAt"
    FROM users u
    INNER JOIN roles r ON r.role_id = u.role_id
    INNER JOIN plans p ON p.plan_id = u.plan_id
    WHERE LOWER(u.email) = LOWER($1)
    LIMIT 1
  `;

  const { rows } = await pool.query(query, [email]);
  return rows[0] ?? null;
};
