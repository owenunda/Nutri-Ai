import pool from '../../database/connection.js';

export const findCode = async (userId, purpose) => {
  const { rows } = await pool.query(
    `SELECT
       code_hash AS "codeHash",
       expires_at AS "expiresAt",
       attempts,
       created_at AS "createdAt"
     FROM email_codes
     WHERE user_id = $1 AND purpose = $2
     LIMIT 1`,
    [userId, purpose]
  );
  return rows[0] ?? null;
};

// Un solo código vigente por usuario y propósito: uno nuevo reemplaza al anterior.
export const upsertCode = async ({ userId, purpose, codeHash, expiresAt }) => {
  await pool.query(
    `INSERT INTO email_codes (user_id, purpose, code_hash, expires_at)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id, purpose) DO UPDATE
       SET code_hash = EXCLUDED.code_hash,
           expires_at = EXCLUDED.expires_at,
           attempts = 0,
           created_at = CURRENT_TIMESTAMP`,
    [userId, purpose, codeHash, expiresAt]
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
