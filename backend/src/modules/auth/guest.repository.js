import pool from '../../database/connection.js';
import { createUser } from './auth.repository.js';

/** Alimentos del catálogo común para las comidas de ejemplo. */
export const findSampleFoodIds = async (limit = 6) => {
  const { rows } = await pool.query(
    `SELECT food_id AS "foodId"
     FROM foods
     WHERE is_global = TRUE AND is_active = TRUE
     ORDER BY food_id
     LIMIT $1`,
    [limit]
  );
  return rows.map((row) => row.foodId);
};

/**
 * Crea al invitado con su perfil y sus datos de ejemplo. Todo o nada: un
 * invitado a medias dejaría el inicio roto.
 * @returns {Promise<number>} userId
 */
export const createGuestAccount = async ({ user, expiresAt, profile, sample }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const { userId } = await createUser(user, client);

    await client.query(
      'UPDATE users SET guest_expires_at = $2, age = $3 WHERE user_id = $1',
      [userId, expiresAt, profile.age]
    );

    for (const { day, height, weight } of sample.physical) {
      await client.query(
        'INSERT INTO physical_records (user_id, height, weight, record_date) VALUES ($1, $2, $3, $4)',
        [userId, height, weight, day]
      );
    }

    for (const { day, glasses } of sample.water) {
      await client.query(
        'INSERT INTO water_intake (user_id, day, glasses) VALUES ($1, $2, $3)',
        [userId, day, glasses]
      );
    }

    for (const { day, items } of sample.meals) {
      const { rows } = await client.query(
        'INSERT INTO meal_records (user_id, record_date) VALUES ($1, $2) RETURNING meal_record_id AS "mealRecordId"',
        [userId, day]
      );
      for (const { foodId, quantity, mealType } of items) {
        await client.query(
          'INSERT INTO meal_record_details (meal_record_id, food_id, quantity, meal_type) VALUES ($1, $2, $3, $4)',
          [rows[0].mealRecordId, foodId, quantity, mealType]
        );
      }
    }

    await client.query('COMMIT');
    return userId;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/** Invitados vencidos, el más viejo primero. */
export const findExpiredGuestIds = async (limit = 100) => {
  const { rows } = await pool.query(
    `SELECT user_id AS "userId"
     FROM users
     WHERE guest_expires_at IS NOT NULL AND guest_expires_at <= NOW()
     ORDER BY guest_expires_at
     LIMIT $1`,
    [limit]
  );
  return rows.map((row) => row.userId);
};

/** Invitados que todavía no vencen. */
export const countActiveGuests = async () => {
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM users WHERE guest_expires_at > NOW()'
  );
  return rows[0].count;
};
