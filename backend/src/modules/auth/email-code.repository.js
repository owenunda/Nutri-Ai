import pool from '../../database/connection.js';

// Los tiempos se calculan en la base: las columnas son TIMESTAMP sin zona
// horaria y Node las leería en la zona del servidor, no en la de PostgreSQL.
export const findCode = async (userId, purpose) => {
  const { rows } = await pool.query(
    `SELECT
       code_hash AS "codeHash",
       attempts,
       EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))::int AS "secondsSinceCreated",
       (expires_at <= CURRENT_TIMESTAMP) AS expired
     FROM email_codes
     WHERE user_id = $1 AND purpose = $2
     LIMIT 1`,
    [userId, purpose]
  );
  return rows[0] ?? null;
};

// Un solo código vigente por usuario y propósito: uno nuevo reemplaza al anterior.
export const upsertCode = async ({ userId, purpose, codeHash, ttlMinutes }) => {
  await pool.query(
    `INSERT INTO email_codes (user_id, purpose, code_hash, expires_at)
     VALUES ($1, $2, $3, CURRENT_TIMESTAMP + make_interval(mins => $4))
     ON CONFLICT (user_id, purpose) DO UPDATE
       SET code_hash = EXCLUDED.code_hash,
           expires_at = EXCLUDED.expires_at,
           attempts = 0,
           created_at = CURRENT_TIMESTAMP`,
    [userId, purpose, codeHash, ttlMinutes]
  );
};

export const incrementCodeAttempts = async (userId, purpose) => {
  await pool.query(
    'UPDATE email_codes SET attempts = attempts + 1 WHERE user_id = $1 AND purpose = $2',
    [userId, purpose]
  );
};

export const deleteCode = async (userId, purpose) => {
  await pool.query('DELETE FROM email_codes WHERE user_id = $1 AND purpose = $2', [
    userId,
    purpose,
  ]);
};
