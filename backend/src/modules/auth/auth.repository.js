import pool from '../../database/connection.js';

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

export const getDefaultRoleAndPlanIds = async () => {
  const query = `
    SELECT
      (SELECT role_id FROM roles WHERE name = 'USER' LIMIT 1) AS "roleId",
      (SELECT plan_id FROM plans WHERE name = 'FREE' LIMIT 1) AS "planId"
  `;

  const { rows } = await pool.query(query);
  return rows[0] ?? null;
};

export const createUser = async ({ name, email, passwordHash, goal, roleId, planId }) => {
  const query = `
    INSERT INTO users (name, email, password, goal, role_id, plan_id)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING
      user_id AS "userId",
      name,
      email,
      goal,
      role_id AS "roleId",
      plan_id AS "planId",
      created_at AS "createdAt",
      updated_at AS "updatedAt"
  `;

  const values = [name, email, passwordHash, goal, roleId, planId];
  const { rows } = await pool.query(query, values);

  return rows[0];
};
