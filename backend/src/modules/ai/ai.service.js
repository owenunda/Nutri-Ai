import pool from '../../database/connection.js';
import { AppError } from '../../utils/AppError.js';
import { getRecipeByIdRepository } from '../recipe/recipe.repository.js';

export const saveGeneratedRecipeService = async (userId, recipeData) => {
  const { name, description, ingredients } = recipeData;
  const client = await pool.connect();

  try {
    if (!name || !ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      throw new AppError('Datos de receta incompletos (nombre e ingredientes requeridos)', 400, 'INCOMPLETE_RECIPE_DATA');
    }

    await client.query('BEGIN');

    const recipeQuery = `
      INSERT INTO recipes (name, description)
      VALUES ($1, $2)
      RETURNING recipe_id
    `;
    const recipeResult = await client.query(recipeQuery, [name, description || 'Generada por NutriLife']);
    const recipeId = recipeResult.rows[0].recipe_id;

    const userRecipeQuery = `
      INSERT INTO user_recipes (user_id, recipe_id, status_id, recipe_date)
      VALUES ($1, $2, 1, CURRENT_DATE)
    `;
    await client.query(userRecipeQuery, [userId, recipeId]);

    for (const ing of ingredients) {
      const { food_id, quantity, unit } = ing;
      if (!food_id || !quantity) {
        throw new AppError('Cada ingrediente debe tener food_id y quantity', 400, 'INVALID_INGREDIENT');
      }
      
      const ingredientQuery = `
        INSERT INTO recipe_ingredients (recipe_id, food_id, quantity, unit)
        VALUES ($1, $2, $3, $4)
      `;
      await client.query(ingredientQuery, [recipeId, food_id, quantity, unit || 'g']);
    }

    await client.query('COMMIT');

    return await getRecipeByIdRepository(userId, recipeId);
  } catch (error) {
    await client.query('ROLLBACK');
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'AI_SERVICE_ERROR');
  } finally {
    client.release();
  }
};
