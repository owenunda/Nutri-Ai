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

export const createPhysicalRecord = async (userId, { height, weight }) => {
  const existingUserResult = await pool.query(
    `
      SELECT user_id AS "userId"
      FROM users
      WHERE user_id = $1
      LIMIT 1
    `,
    [userId]
  );

  if (existingUserResult.rows.length === 0) {
    return null;
  }

  const query = `
    INSERT INTO physical_records (user_id, height, weight)
    VALUES ($1, $2, $3)
    RETURNING
      physical_record_id AS "physicalRecordId",
      user_id AS "userId",
      height,
      weight,
      record_date AS "recordDate",
      created_at AS "createdAt"
  `;

  const { rows } = await pool.query(query, [userId, height, weight]);
  return rows[0] ?? null;
};
