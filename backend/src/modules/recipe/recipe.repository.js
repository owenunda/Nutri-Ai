import pool from "../../database/connection.js";
import { AppError } from "../../utils/AppError.js";

export const getAllRecipesRepository = async (userId) => {
    try {
        const query = `
            SELECT 
                r.recipe_id, 
                r.name, 
                r.description, 
                r.created_at,
                ur.status_id,
                s.name AS status_name,
                ur.recipe_date,
                COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'food_id', f.food_id,
                                'name', f.name,
                                'quantity', ri.quantity,
                                'unit', ri.unit,
                                'calories_per_unit', f.calories_per_unit,
                                'base_unit', f.base_unit,
                                'is_global', f.is_global,
                                'created_by_user_id', f.created_by_user_id,
                                'created_at', f.created_at,
                                'updated_at', f.updated_at
                            )
                        )
                        FROM recipe_ingredients ri
                        JOIN foods f ON ri.food_id = f.food_id
                        WHERE ri.recipe_id = r.recipe_id
                    ), 
                    '[]'::json
                ) AS ingredients
            FROM recipes r
            JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
            JOIN statuses s ON ur.status_id = s.status_id
            WHERE ur.user_id = $1
            ORDER BY r.created_at DESC;
        `;
        const { rows } = await pool.query(query, [userId]);
        return rows;
    } catch (error) {
        throw error;
    }
};

export const getRecipeByIdRepository = async (userId, recipeId) => {
    try {
        const query = `
            SELECT 
                r.recipe_id, 
                r.name, 
                r.description, 
                r.created_at,
                ur.status_id,
                s.name AS status_name,
                ur.recipe_date,
                COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'food_id', f.food_id,
                                'name', f.name,
                                'quantity', ri.quantity,
                                'unit', ri.unit,
                                'calories_per_unit', f.calories_per_unit,
                                'base_unit', f.base_unit,
                                'is_global', f.is_global,
                                'created_by_user_id', f.created_by_user_id,
                                'created_at', f.created_at,
                                'updated_at', f.updated_at
                            )
                        )
                        FROM recipe_ingredients ri
                        JOIN foods f ON ri.food_id = f.food_id
                        WHERE ri.recipe_id = r.recipe_id
                    ), 
                    '[]'::json
                ) AS ingredients
            FROM recipes r
            JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
            JOIN statuses s ON ur.status_id = s.status_id
            WHERE r.recipe_id = $1 AND ur.user_id = $2
        `;
        const { rows } = await pool.query(query, [recipeId, userId]);
        return rows[0] || null;
    } catch (error) {
        throw error;
    }
};
export const createRecipeRepository = async (userId, name, description) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const existingRecipe = await client.query(`
            SELECT r.recipe_id 
            FROM recipes r
            JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
            WHERE r.name = $1 AND ur.user_id = $2
        `, [name, userId]);

        if (existingRecipe.rows.length > 0) {
            throw new AppError('Recipe already exists for this user', 400, 'RECIPE_ALREADY_EXISTS', {
                existingRecipe: existingRecipe.rows[0]
            });
        }

        const recipeQuery = `
            INSERT INTO recipes (name, description)
            VALUES ($1, $2)
            RETURNING recipe_id, name, description, created_at;
        `;
        const recipeResult = await client.query(recipeQuery, [name, description]);
        const newRecipe = recipeResult.rows[0];

        // Obtener un status_id (ej: 'ACCEPTED') para la relacin
        const statusQuery = await client.query(`SELECT status_id FROM statuses WHERE name = 'ACCEPTED' LIMIT 1`);
        const statusId = statusQuery.rows.length > 0 ? statusQuery.rows[0].status_id : 1;

        const userRecipeQuery = `
            INSERT INTO user_recipes (user_id, recipe_id, status_id, recipe_date)
            VALUES ($1, $2, $3, CURRENT_DATE)
        `;
        await client.query(userRecipeQuery, [userId, newRecipe.recipe_id, statusId]);

        await client.query('COMMIT');
        return newRecipe;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};
export const addIngredientsToRecipeRepository = async (userId, recipeId, ingredients) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const recipeCheck = await client.query(`
            SELECT r.recipe_id 
            FROM recipes r
            JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
            WHERE r.recipe_id = $1 AND ur.user_id = $2
        `, [recipeId, userId]);

        if (recipeCheck.rows.length === 0) {
            throw new AppError('Recipe not found or does not belong to user', 404, 'RECIPE_NOT_FOUND');
        }
        for (const ingredient of ingredients) {
            const { food_id, quantity, unit } = ingredient;
            try {
                await client.query(`
                    INSERT INTO recipe_ingredients (recipe_id, food_id, quantity, unit)
                    VALUES ($1, $2, $3, $4)
                `, [recipeId, food_id, quantity, unit]);
            } catch (error) {
                if (error.code === '23505') { 
                    throw new AppError(`Ingredient with food_id ${food_id} already exists in this recipe`, 400, 'DUPLICATE_INGREDIENT');
                }
                throw error;
            }
        }

        await client.query('COMMIT');
        
        const fetchQuery = `
            SELECT 
                r.recipe_id, 
                r.name, 
                r.description, 
                r.created_at,
                ur.status_id,
                s.name AS status_name,
                ur.recipe_date,
                COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'food_id', f.food_id,
                                'name', f.name,
                                'quantity', ri.quantity,
                                'unit', ri.unit,
                                'calories_per_unit', f.calories_per_unit,
                                'base_unit', f.base_unit,
                                'is_global', f.is_global,
                                'created_by_user_id', f.created_by_user_id,
                                'created_at', f.created_at,
                                'updated_at', f.updated_at
                            )
                        )
                        FROM recipe_ingredients ri
                        JOIN foods f ON ri.food_id = f.food_id
                        WHERE ri.recipe_id = r.recipe_id
                    ), 
                    '[]'::json
                ) AS ingredients
            FROM recipes r
            JOIN user_recipes ur ON r.recipe_id = ur.recipe_id
            JOIN statuses s ON ur.status_id = s.status_id
            WHERE r.recipe_id = $1 AND ur.user_id = $2
        `;
        const result = await client.query(fetchQuery, [recipeId, userId]);
        return result.rows[0];
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};