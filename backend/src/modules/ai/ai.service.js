import pool from '../../database/connection.js';
import { AppError } from '../../utils/AppError.js';
import { getRecipeByIdRepository } from '../recipe/recipe.repository.js';
import { checkFoodsVisible } from '../food/food.repository.js';

export const saveGeneratedRecipeService = async (userId, recipeData) => {
  const { name, description, ingredients } = recipeData;
  const client = await pool.connect();
  let transactionStarted = false;

  try {
    if (!name || !ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      throw new AppError('Datos de receta incompletos (nombre e ingredientes requeridos)', 400, 'INCOMPLETE_RECIPE_DATA');
    }

    for (const ingredient of ingredients) {
      if (!ingredient?.food_id || !ingredient?.quantity) {
        throw new AppError('Cada ingrediente debe tener food_id y quantity', 400, 'INVALID_INGREDIENT');
      }
    }

    await client.query('BEGIN');
    transactionStarted = true;

    const foodIds = ingredients.map(({ food_id }) => food_id);
    const visibleFoodIds = new Set(
      (await checkFoodsVisible(userId, foodIds, client)).map(Number)
    );
    if (foodIds.some((foodId) => !visibleFoodIds.has(Number(foodId)))) {
      throw new AppError('Uno o más alimentos no están disponibles', 404, 'FOOD_NOT_FOUND');
    }

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
      const ingredientQuery = `
        INSERT INTO recipe_ingredients (recipe_id, food_id, quantity, unit)
        VALUES ($1, $2, $3, $4)
      `;
      await client.query(ingredientQuery, [recipeId, food_id, quantity, unit || 'g']);
    }

    await client.query('COMMIT');
    transactionStarted = false;

    return await getRecipeByIdRepository(userId, recipeId);
  } catch (error) {
    if (transactionStarted) await client.query('ROLLBACK');
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'AI_SERVICE_ERROR');
  } finally {
    client.release();
  }
};
