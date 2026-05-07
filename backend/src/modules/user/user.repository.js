import pool from '../../database/connection.js';

const profileSelectQuery = `
  SELECT
    u.user_id AS "userId",
    u.name,
    u.email,
    u.age,
    u.goal,
    r.name AS role,
    p.name AS plan,
    pr.height,
    pr.weight,
    pr.record_date AS "recordDate",
    u.created_at AS "createdAt",
    u.updated_at AS "updatedAt"
  FROM users u
  INNER JOIN roles r ON r.role_id = u.role_id
  INNER JOIN plans p ON p.plan_id = u.plan_id
  LEFT JOIN LATERAL (
    SELECT
      height,
      weight,
      record_date
    FROM physical_records
    WHERE user_id = u.user_id
    ORDER BY record_date DESC, physical_record_id DESC
    LIMIT 1
  ) pr ON true
  WHERE u.user_id = $1
  LIMIT 1
`;

export const findUserProfileById = async (userId) => {
  const { rows } = await pool.query(profileSelectQuery, [userId]);
  return rows[0] ?? null;
};

export const updateUserProfileData = async (userId, { age, goal, height, weight }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const existingUserResult = await client.query(
      `
        SELECT user_id AS "userId"
        FROM users
        WHERE user_id = $1
        LIMIT 1
      `,
      [userId]
    );

    if (existingUserResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return null;
    }

    const userFields = [];
    const userValues = [];
    let userIndex = 1;

    if (age !== undefined) {
      userFields.push(`age = $${userIndex}`);
      userValues.push(age);
      userIndex++;
    }

    if (goal !== undefined) {
      userFields.push(`goal = $${userIndex}`);
      userValues.push(goal);
      userIndex++;
    }

    if (userFields.length > 0) {
      userValues.push(userId);

      await client.query(
        `
          UPDATE users
          SET ${userFields.join(', ')}, updated_at = NOW()
          WHERE user_id = $${userIndex}
        `,
        userValues
      );
    }

    if (height !== undefined || weight !== undefined) {
      const latestPhysicalRecordResult = await client.query(
        `
          SELECT height, weight
          FROM physical_records
          WHERE user_id = $1
          ORDER BY record_date DESC, physical_record_id DESC
          LIMIT 1
        `,
        [userId]
      );

      const latestPhysicalRecord = latestPhysicalRecordResult.rows[0] ?? {};
      const nextHeight = height !== undefined ? height : latestPhysicalRecord.height ?? null;
      const nextWeight = weight !== undefined ? weight : latestPhysicalRecord.weight ?? null;

      await client.query(
        `
          INSERT INTO physical_records (user_id, height, weight)
          VALUES ($1, $2, $3)
        `,
        [userId, nextHeight, nextWeight]
      );
    }

    const { rows } = await client.query(profileSelectQuery, [userId]);

    await client.query('COMMIT');
    return rows[0] ?? null;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
