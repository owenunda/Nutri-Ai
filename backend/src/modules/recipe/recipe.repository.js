import pool from "../../database/connection.js";
import { AppError } from "../../utils/AppError.js";

export const getAllRecipesRepository = async (userId) => {
    try {
        return "coming soon";
    } catch (error) {
        throw error;
    }
};
export const createRecipeRepository = async (userId, name) => {
    try {
        const existingRecipe = await pool.query(`
            SELECT recipe_id FROM recipes WHERE name = $1 AND created_by_user_id = $2
        `, [name, userId]);
        if (existingRecipe.rows.length > 0) {
            throw new AppError('Recipe already exists', 400, 'RECIPE_ALREADY_EXISTS', {
                existingRecipe: existingRecipe.rows[0]
            });
        }
        const query = `
            INSERT INTO recipes (name, created_by_user_id)
            VALUES ($1, $2)
            RETURNING recipe_id, name, created_at, created_by_user_id;
        `;
        const { rows } = await pool.query(query, [name, userId]);
        return rows[0];
    } catch (error) {
        throw error;
    }
};

export const addIngredientsToRecipeRepository = async (userId, recipeId, ingredients) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const recipeCheck = await client.query(`
            SELECT recipe_id FROM recipes WHERE recipe_id = $1 AND created_by_user_id = $2
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
                if (error.code === '23505') { // Unique violation (if ON CONFLICT wasn't used)
                    throw new AppError(`Ingredient with food_id ${food_id} already exists in this recipe`, 400, 'DUPLICATE_INGREDIENT');
                }
                throw error;
            }
        }

        await client.query('COMMIT');
        return { success: true };
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};