import pool from "../../database/conection.js";

export const getAllRecipesRepository = async (temporalId) => {
    try {
        const sql = `SELECT * FROM recipes where recipe_id = $1`;
        const { rows } = await pool.query(sql, [temporalId]);
        return rows;
    } catch (error) {
        throw error;
    }
};