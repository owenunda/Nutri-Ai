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