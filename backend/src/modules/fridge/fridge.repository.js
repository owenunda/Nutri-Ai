import pool from '../../database/connection.js';

export const getFridgeByUserIdRepository = async (userId) => {
    const query = `
        SELECT
            fr.fridge_id AS "fridgeId",
            fr.user_id AS "userId",
            fr.created_at AS "createdAt",
            fr.updated_at AS "updatedAt",
            COALESCE(
                json_agg(
                    json_build_object(
                        'fridgeItemId', fi.fridge_item_id,
                        'foodId', f.food_id,
                        'name', f.name,
                        'quantity', fi.quantity,
                        'unit', fi.unit,
                        'caloriesPerUnit', f.calories_per_unit,
                        'baseUnit', f.base_unit,
                        'isGlobal', f.is_global,
                        'createdByUserId', f.created_by_user_id,
                        'updatedAt', fi.updated_at
                    )
                    ORDER BY fi.fridge_item_id
                ) FILTER (WHERE fi.fridge_item_id IS NOT NULL),
                '[]'::json
            ) AS items
        FROM fridges fr
        LEFT JOIN fridge_items fi ON fi.fridge_id = fr.fridge_id
        LEFT JOIN foods f ON f.food_id = fi.food_id
        WHERE fr.user_id = $1
        GROUP BY fr.fridge_id, fr.user_id, fr.created_at, fr.updated_at
    `;

    const { rows } = await pool.query(query, [userId]);
    return rows[0] || null;
};
