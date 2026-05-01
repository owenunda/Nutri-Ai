import { getAllRecipesRepository, createRecipeRepository, addIngredientsToRecipeRepository, getRecipeByIdRepository, updateRecipeStatusRepository } from "./recipe.repository.js";
import { checkFoodsExist } from "../food/food.repository.js";
import { AppError } from "../../utils/AppError.js";

export const getAllRecipesService = async (userId) => {
  try {
    const recipes = await getAllRecipesRepository(userId);
    if (!recipes || recipes.length === 0) {
      throw new AppError('No se encontraron recetas', 404, 'RECIPE_NOT_FOUND');
    }
    return recipes;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};

export const getRecipeByIdService = async (userId, recipeId) => {
  try {
    const recipe = await getRecipeByIdRepository(userId, recipeId);
    if (!recipe) {
      throw new AppError('Recipe not found or does not belong to user', 404, 'RECIPE_NOT_FOUND');
    }
    return recipe;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};

export const createRecipeService = async (userId, name, description) => {
  try {
    if (!name) {
      throw new AppError('El nombre de la receta es requerido', 400, 'RECIPE_NAME_REQUIRED');
    }
    const recipe = await createRecipeRepository(userId, name, description);
    return recipe;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};

export const addIngredientsToRecipeService = async (userId, recipeId, ingredients) => {
  try {
    if (!Array.isArray(ingredients) || ingredients.length === 0) {
      throw new AppError('Se requiere una lista de ingredientes', 400, 'INGREDIENTS_REQUIRED');
    }

    const foodIds = [];
    for (const ingredient of ingredients) {
      const { food_id, quantity, unit } = ingredient;

      if (!food_id) {
        throw new AppError('food_id es requerido para todos los ingredientes', 400, 'FOOD_ID_REQUIRED');
      }

      if (typeof quantity !== 'number' || quantity <= 0) {
        throw new AppError(`La cantidad debe ser mayor a 0 para el alimento ${food_id}`, 400, 'INVALID_QUANTITY');
      }

      if (!unit) {
        throw new AppError(`La unidad es requerida para el alimento ${food_id}`, 400, 'UNIT_REQUIRED');
      }

      foodIds.push(food_id);
    }

    // Check if all foods exist
    const existingFoodIds = await checkFoodsExist(foodIds);
    const missingFoodIds = foodIds.filter(id => !existingFoodIds.includes(id));

    if (missingFoodIds.length > 0) {
      throw new AppError(`Los siguientes alimentos no existen: ${missingFoodIds.join(', ')}`, 404, 'FOOD_NOT_FOUND');
    }

    const recipe = await addIngredientsToRecipeRepository(userId, recipeId, ingredients);
    return recipe;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};

export const updateRecipeStatusService = async (userId, recipeId, statusId) => {
  try {
    if (!statusId) {
      throw new AppError('El ID de estado es requerido', 400, 'STATUS_ID_REQUIRED');
    }
    const recipe = await updateRecipeStatusRepository(userId, recipeId, statusId);
    return recipe;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};