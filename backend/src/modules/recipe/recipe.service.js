import { getAllRecipesRepository } from "./recipe.repository.js";
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