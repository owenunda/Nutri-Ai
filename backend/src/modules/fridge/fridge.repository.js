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

// Actualiza la cantidad de un item en la nevera, verificando propiedad
export const updateFridgeItemRepository = async (itemId, userId, quantity) => {
    const query = `
        UPDATE fridge_items
        SET quantity = $1, updated_at = NOW()
        WHERE fridge_item_id = $2
        AND fridge_id = (SELECT fridge_id FROM fridges WHERE user_id = $3)
        RETURNING
            fridge_item_id AS "fridgeItemId",
            fridge_id      AS "fridgeId",
            food_id        AS "foodId",
            quantity,
            unit
    `;

    const { rows } = await pool.query(query, [quantity, itemId, userId]);
    return rows[0] || null;
};

// Elimina un item de la nevera, validando propiedad del usuario
export const deleteFridgeItemRepository = async (itemId, userId) => {
    // Primero, obtener el food_id del item a eliminar
    const getItemQuery = `
        SELECT fi.food_id, f.is_global, f.created_by_user_id
        FROM fridge_items fi
        JOIN foods f ON f.food_id = fi.food_id
        WHERE fi.fridge_item_id = $1
        AND fi.fridge_id = (SELECT fridge_id FROM fridges WHERE user_id = $2)
    `;
    const { rows: itemRows } = await pool.query(getItemQuery, [itemId, userId]);
    if (itemRows.length === 0) {
        return null; // Item no encontrado o no pertenece al usuario
    }

    const { food_id, is_global, created_by_user_id } = itemRows[0];

    // Eliminar el item de la nevera
    const deleteQuery = `
        DELETE FROM fridge_items
        WHERE fridge_item_id = $1
        AND fridge_id = (SELECT fridge_id FROM fridges WHERE user_id = $2)
        RETURNING
            fridge_item_id AS "fridgeItemId",
            fridge_id      AS "fridgeId",
            food_id        AS "foodId",
            quantity,
            unit
    `;
    const { rows } = await pool.query(deleteQuery, [itemId, userId]);
    if (rows.length === 0) {
        return null;
    }

    // Si el alimento es personalizado y creado por el usuario, desactivarlo
    if (!is_global && created_by_user_id === userId) {
        const deactivateQuery = `
            UPDATE foods
            SET is_active = false, updated_at = NOW()
            WHERE food_id = $1
        `;
        await pool.query(deactivateQuery, [food_id]);
    }

    return rows[0];
};
