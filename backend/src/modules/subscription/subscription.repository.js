import pool from '../../database/connection.js';

/** Corre fn(client) dentro de una transacción. */
export const inTransaction = async (fn) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Lo que necesita la regla del plan, bloqueando la fila del usuario hasta el
 * fin de la transacción.
 * @returns {Promise<{plan: string, giftPro: boolean, giftProUntil: Date|null, storeExpiresAt: Date|null}|null>}
 */
export const lockPlanInputs = async (client, userId) => {
  const { rows } = await client.query(
    `SELECT p.name AS plan,
            u.gift_pro AS "giftPro",
            u.gift_pro_until AS "giftProUntil",
            ss.expires_at AS "storeExpiresAt"
       FROM users u
       INNER JOIN plans p ON p.plan_id = u.plan_id
       LEFT JOIN store_subscriptions ss ON ss.user_id = u.user_id
      WHERE u.user_id = $1
      FOR UPDATE OF u`,
    [userId]
  );
  return rows[0] ?? null;
};

export const upsertStoreSubscription = async (client, userId, state) => {
  await client.query(
    `INSERT INTO store_subscriptions
       (user_id, product_id, store, expires_at, will_renew, billing_issue, environment, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id) DO UPDATE SET
       product_id = EXCLUDED.product_id,
       store = EXCLUDED.store,
       expires_at = EXCLUDED.expires_at,
       will_renew = EXCLUDED.will_renew,
       billing_issue = EXCLUDED.billing_issue,
       environment = EXCLUDED.environment,
       updated_at = CURRENT_TIMESTAMP`,
    [userId, state.productId, state.store, state.expiresAt, state.willRenew, state.billingIssue, state.environment]
  );
};

export const setGift = async (client, userId, { giftPro, giftProUntil }) => {
  await client.query(
    `UPDATE users SET gift_pro = $2, gift_pro_until = $3, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1`,
    [userId, giftPro, giftProUntil]
  );
};

/** @returns {Promise<{userId: number, plan: string, proUntil: Date|null}>} */
export const setEffectivePlan = async (client, userId, { plan, proUntil }) => {
  const { rows } = await client.query(
    `UPDATE users u
        SET plan_id = p.plan_id, pro_until = $3, updated_at = CURRENT_TIMESTAMP
       FROM plans p
      WHERE u.user_id = $1 AND p.name = $2
      RETURNING u.user_id AS "userId", p.name AS plan, u.pro_until AS "proUntil"`,
    [userId, plan, proUntil]
  );
  return rows[0];
};

/** De una lista de ids, los que existen en users. */
export const findExistingUserIds = async (ids) => {
  const { rows } = await pool.query('SELECT user_id AS "userId" FROM users WHERE user_id = ANY($1::int[])', [ids]);
  return rows.map((row) => row.userId);
};

/**
 * Suscriptores que iban a renovar y cuyo PRO vence pronto o ya venció: el job
 * de vencimiento le pregunta a RevenueCat por ellos antes de bajarlos.
 * @returns {Promise<number[]>} user_id, el PRO más próximo a vencer primero.
 */
export const findStoreRenewalsDue = async ({ lookaheadMs, waitMs, limit }) => {
  const { rows } = await pool.query(
    `SELECT u.user_id AS "userId"
       FROM users u
       INNER JOIN store_subscriptions ss ON ss.user_id = u.user_id
      WHERE ss.will_renew = TRUE
        AND ss.expires_at > NOW() - ($2::bigint * INTERVAL '1 millisecond')
        AND u.pro_until IS NOT NULL
        AND u.pro_until <= NOW() + ($1::bigint * INTERVAL '1 millisecond')
      ORDER BY u.pro_until
      LIMIT $3`,
    [lookaheadMs, waitMs, limit]
  );
  return rows.map((row) => row.userId);
};
