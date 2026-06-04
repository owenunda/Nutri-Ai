import { createMealRecordRepository, addItemsToMealRepository, findMealRecordByUserAndDate } from './meal.repository.js';
import { checkFoodsExist } from '../food/food.repository.js';
import { checkRecipesExist } from '../recipe/recipe.repository.js';
import { AppError } from '../../utils/AppError.js';

export const createMealService = async (userId, date) => {
  try {
    const mealDate = date || new Date().toISOString().split('T')[0];
    
    const existing = await findMealRecordByUserAndDate(userId, mealDate);
    if (existing) {
      return existing;
    }

    const mealRecord = await createMealRecordRepository(userId, mealDate);
    return mealRecord;
  } catch (error) {
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};

export const addItemsToMealService = async (userId, mealRecordId, items) => {
  try {
    if (!Array.isArray(items) || items.length === 0) {
      throw new AppError('Se requiere una lista de ítems', 400, 'ITEMS_REQUIRED');
    }

    const foodIds = items.filter(i => i.food_id).map(i => i.food_id);
    const recipeIds = items.filter(i => i.recipe_id).map(i => i.recipe_id);

    if (foodIds.length > 0) {
      const existingFoodIds = await checkFoodsExist(foodIds);
      const missingFoods = foodIds.filter(id => !existingFoodIds.includes(id));
      if (missingFoods.length > 0) {
        throw new AppError(`Alimentos no encontrados: ${missingFoods.join(', ')}`, 404, 'FOOD_NOT_FOUND');
      }
    }

    if (recipeIds.length > 0) {
      const existingRecipeIds = await checkRecipesExist(userId, recipeIds);
      const missingRecipes = recipeIds.filter(id => !existingRecipeIds.includes(id));
      if (missingRecipes.length > 0) {
        throw new AppError(`Recetas no encontradas o no pertenecen al usuario: ${missingRecipes.join(', ')}`, 404, 'RECIPE_NOT_FOUND');
      }
    }

    for (const item of items) {
      if (typeof item.quantity !== 'number' || item.quantity <= 0) {
        throw new AppError('La cantidad debe ser un número mayor a 0', 400, 'INVALID_QUANTITY');
      }
      if (!item.food_id && !item.recipe_id) {
        throw new AppError('Cada ítem debe tener un food_id o un recipe_id', 400, 'ID_REQUIRED');
      }
    }

    const results = await addItemsToMealRepository(mealRecordId, items);
    return results;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};

export const addRecipesToMealService = async (userId, mealRecordId, recipes) => {
  try {
    if (!Array.isArray(recipes) || recipes.length === 0) {
      throw new AppError('Se requiere una lista de recetas', 400, 'RECIPES_REQUIRED');
    }

    const recipeIds = recipes.map(r => r.recipe_id);
    const existingRecipeIds = await checkRecipesExist(userId, recipeIds);
    const missingRecipes = recipeIds.filter(id => !existingRecipeIds.includes(id));

    if (missingRecipes.length > 0) {
      throw new AppError(`Recetas no encontradas: ${missingRecipes.join(', ')}`, 404, 'RECIPE_NOT_FOUND');
    }

    const items = recipes.map(r => ({
      recipe_id: r.recipe_id,
      quantity: r.quantity
    }));

    return await addItemsToMealService(userId, mealRecordId, items);
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};
