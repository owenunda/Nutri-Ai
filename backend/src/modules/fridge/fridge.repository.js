import pool from '../../database/connection.js';

export const getFridgeByUserIdRepository = async (userId) => {
    const query = `
        SELECT
            fr.fridge_id  AS "fridgeId",
            fr.user_id    AS "userId",
            fr.created_at AS "createdAt",
            fr.updated_at AS "updatedAt",
            COALESCE(
                json_agg(
                    json_build_object(
                        'fridgeItemId', fi.fridge_item_id,
                        'name',         f.name,
                        'quantity',     fi.quantity,
                        'unit',         fi.unit
                    )
                    ORDER BY fi.fridge_item_id
                ) FILTER (WHERE fi.fridge_item_id IS NOT NULL),
                '[]'::json
            ) AS items
        FROM fridges fr
        LEFT JOIN fridge_items fi ON fi.fridge_id = fr.fridge_id
        LEFT JOIN foods f ON f.food_id = fi.food_id
            AND f.is_active = true
            AND (f.is_global = true OR f.created_by_user_id = $1)
        WHERE fr.user_id = $1
        GROUP BY fr.fridge_id, fr.user_id, fr.created_at, fr.updated_at
    `;

    const { rows } = await pool.query(query, [userId]);
    return rows[0] || null;
};
// Crea una nevera nueva para el usuario recién registrado
export const createFridgeRepository = async (userId) => {
    const query = `
        INSERT INTO fridges (user_id)
        VALUES ($1)
        RETURNING
            fridge_id  AS "fridgeId",
            user_id    AS "userId",
            created_at AS "createdAt",
            updated_at AS "updatedAt"
    `;

    const { rows } = await pool.query(query, [userId]);
    return rows[0];
};

// Agrega un alimento a la nevera con cantidad inicial en 0
export const addFridgeItemRepository = async (fridgeId, foodId, unit) => {
    const query = `
        INSERT INTO fridge_items (fridge_id, food_id, quantity, unit)
        VALUES ($1, $2, 0, $3)
        RETURNING
            fridge_item_id AS "fridgeItemId",
            fridge_id      AS "fridgeId",
            food_id        AS "foodId",
            quantity,
            unit
    `;

    const { rows } = await pool.query(query, [fridgeId, foodId, unit]);
    return rows[0];
};

// Agrega o actualiza un item en la nevera (upsert)
export const addOrUpdateFridgeItemRepository = async (fridgeId, foodId, quantity, unit) => {
    const query = `
        INSERT INTO fridge_items (fridge_id, food_id, quantity, unit)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (fridge_id, food_id)
        DO UPDATE SET
            quantity = fridge_items.quantity + EXCLUDED.quantity,
            unit = EXCLUDED.unit,
            updated_at = NOW()
        RETURNING
            fridge_item_id AS "fridgeItemId",
            fridge_id      AS "fridgeId",
            food_id        AS "foodId",
            quantity,
            unit
    `;

    const { rows } = await pool.query(query, [fridgeId, foodId, quantity, unit]);
    return rows[0];
};

// Verifica si un alimento existe y está activo
export const checkFoodExistsRepository = async (foodId) => {
    const query = `
        SELECT food_id AS "foodId", name, is_active AS "isActive"
        FROM foods
        WHERE food_id = $1 AND is_active = true
    `;
    const { rows } = await pool.query(query, [foodId]);
    return rows[0] || null;
};
