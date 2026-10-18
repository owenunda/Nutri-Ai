import pool from '../../database/connection.js';

export const getAuthRepositoryStatus = async () => {
  return {
    layer: 'repository',
    status: 'ready',
  };
};

// Mismo formato de usuario para el login con email y con Google.
const userSelect = `
  SELECT
    u.user_id AS "userId",
    u.name,
    u.email,
    u.password AS "passwordHash",
    u.goal,
    u.age,
    u.email_verified_at AS "emailVerifiedAt",
    r.name AS role,
    p.name AS plan,
    u.pro_until AS "proUntil",
    u.guest_expires_at AS "guestExpiresAt",
    u.created_at AS "createdAt",
    u.updated_at AS "updatedAt"
  FROM users u
  INNER JOIN roles r ON r.role_id = u.role_id
  INNER JOIN plans p ON p.plan_id = u.plan_id
`;

export const findUserByEmail = async (email) => {
  const { rows } = await pool.query(
    `${userSelect} WHERE LOWER(u.email) = LOWER($1) LIMIT 1`,
    [email]
  );
  return rows[0] ?? null;
};

export const findUserByProvider = async (provider, providerUserId) => {
  const { rows } = await pool.query(
    `${userSelect}
     INNER JOIN user_auth_providers ap ON ap.user_id = u.user_id
     WHERE ap.provider = $1 AND ap.provider_user_id = $2
     LIMIT 1`,
    [provider, providerUserId]
  );
  return rows[0] ?? null;
};

export const findProviderLink = async (userId, provider) => {
  const { rows } = await pool.query(
    `SELECT provider_user_id AS "providerUserId"
     FROM user_auth_providers
     WHERE user_id = $1 AND provider = $2
     LIMIT 1`,
    [userId, provider]
  );
  return rows[0] ?? null;
};

export const linkAuthProvider = async (
  { userId, provider, providerUserId, email },
  client = pool
) => {
  await client.query(
    `INSERT INTO user_auth_providers (user_id, provider, provider_user_id, email)
     VALUES ($1, $2, $3, $4)`,
    [userId, provider, providerUserId, email]
  );
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

// `emailVerifiedAt` en null: el usuario aún no demostró que el correo es suyo.
export const createUser = async (
  { name, email, passwordHash, goal, roleId, planId, emailVerifiedAt = null },
  client = pool
) => {
  const query = `
    INSERT INTO users (name, email, password, goal, role_id, plan_id, email_verified_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
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

  const values = [name, email, passwordHash, goal, roleId, planId, emailVerifiedAt];
  const { rows } = await client.query(query, values);

  return rows[0];
};

// El usuario y su cuenta externa se crean juntos: un usuario de Google sin
// la fila del proveedor no podría volver a entrar.
export const createUserWithProvider = async ({ provider, providerUserId, ...userData }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const user = await createUser(userData, client);
    await linkAuthProvider(
      { userId: user.userId, provider, providerUserId, email: userData.email },
      client
    );
    await client.query('COMMIT');
    return user;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

// Marca el correo como verificado; si ya lo estaba, conserva la fecha original.
export const markEmailVerified = async (userId) => {
  await pool.query(
    `UPDATE users
     SET email_verified_at = COALESCE(email_verified_at, CURRENT_TIMESTAMP),
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1`,
    [userId]
  );
};

// Restablecer con un código enviado al correo también prueba que el correo es suyo.
export const setPasswordAndVerify = async (userId, passwordHash) => {
  await pool.query(
    `UPDATE users
     SET password = $2,
         email_verified_at = COALESCE(email_verified_at, CURRENT_TIMESTAMP),
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1`,
    [userId, passwordHash]
  );
};
