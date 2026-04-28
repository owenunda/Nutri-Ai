import { getAllRecipesRepository, createRecipeRepository } from "./recipe.repository.js";
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

export const createRecipeService = async (userId, name) => {
  try {
    if (!name) {
      throw new AppError('El nombre de la receta es requerido', 400, 'RECIPE_NAME_REQUIRED');
    }
    const recipe = await createRecipeRepository(userId, name);
    return recipe;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(error.message, 500, 'RECIPE_SERVICE_ERROR', error);
  }
};
