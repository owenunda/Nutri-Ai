import { getAllRecipesService, createRecipeService, addIngredientsToRecipeService } from "./recipe.service.js";
import { successResponse } from "../../utils/response.js";

export const getAllRecipes = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const recipes = await getAllRecipesService(userId);
    return successResponse(res, recipes, 'Recipes fetched successfully');
  } catch (error) {
    next(error);
  }
};

export const createRecipe = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const { name } = req.body;
    const recipes = await createRecipeService(userId, name);
    return successResponse(res, recipes, 'Recipe created successfully');
  } catch (error) {
    next(error);
  }
};

export const addIngredientsToRecipe = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const { recipeId } = req.params;
    const ingredients = req.body;
    const recipes = await addIngredientsToRecipeService(userId, recipeId, ingredients);
    return successResponse(res, [], 'Ingredients added successfully');
  } catch (error) {
    next(error);
  }
};