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
    r.name AS role,
    p.name AS plan,
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

export const createUser = async (
  { name, email, passwordHash, goal, roleId, planId },
  client = pool
) => {
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

// Vincula Google a una cuenta que ya existía y, con `clearPassword`, le borra
// la contraseña. El registro con email no verifica el correo: si la cuenta la
// creó otra persona con el correo del dueño, esa contraseña deja de servir en
// cuanto Google demuestra quién es el dueño real.
export const linkProviderToExistingUser = async ({
  userId,
  provider,
  providerUserId,
  email,
  clearPassword,
}) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await linkAuthProvider({ userId, provider, providerUserId, email }, client);
    if (clearPassword) {
      await client.query(
        'UPDATE users SET password = NULL, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1',
        [userId]
      );
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
