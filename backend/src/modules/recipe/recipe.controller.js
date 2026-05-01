import { getAllRecipesService, createRecipeService, addIngredientsToRecipeService, getRecipeByIdService, updateRecipeStatusService } from "./recipe.service.js";
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

export const getRecipeById = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const { recipeId } = req.params;
    const recipe = await getRecipeByIdService(userId, recipeId);
    return successResponse(res, recipe, 'Recipe fetched successfully');
  } catch (error) {
    next(error);
  }
};

export const createRecipe = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const { name, description } = req.body;
    const recipes = await createRecipeService(userId, name, description);
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
    const recipe = await addIngredientsToRecipeService(userId, recipeId, ingredients);
    return successResponse(res, recipe, 'Ingredients added successfully');
  } catch (error) {
    next(error);
  }
};

export const updateRecipeStatus = async (req, res, next) => {
  try {
    const userId = Number(req.user.userId);
    const { recipeId } = req.params;
    const { status_id } = req.body;
    const recipe = await updateRecipeStatusService(userId, recipeId, status_id);
    return successResponse(res, recipe, 'Estado de la receta actualizado correctamente');
  } catch (error) {
    next(error);
  }
};