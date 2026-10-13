import {
  createMealService,
  addItemsToMealService,
  addRecipesToMealService,
  getDayMealsService,
  deleteMealItemService,
  addRecipeToMealService,
  deleteRecipeLogService,
} from './meal.service.js';
import { successResponse } from '../../utils/response.js';

export const createMeal = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { date } = req.body;
    const mealRecord = await createMealService(userId, date);
    return successResponse(res, mealRecord, 'Registro de comida creado con éxito', 201);
  } catch (error) {
    next(error);
  }
};

export const addMealItems = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { id: mealRecordId } = req.params;
    const items = req.body; // Array de ítems
    const details = await addItemsToMealService(userId, mealRecordId, items);
    return successResponse(res, details, 'Ítems añadidos al registro de comida con éxito', 201);
  } catch (error) {
    next(error);
  }
};

export const addMealRecipes = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { id: mealRecordId } = req.params;
    const recipes = req.body;
    const details = await addRecipesToMealService(userId, mealRecordId, recipes);
    return successResponse(res, details, 'Recetas añadidas al registro de comida con éxito', 201);
  } catch (error) {
    next(error);
  }
};

export const getDayMeals = async (req, res, next) => {
  try {
    const result = await getDayMealsService(req.user.userId, req.query.date);
    return successResponse(res, result, 'Comidas del día obtenidas con éxito');
  } catch (error) {
    next(error);
  }
};

export const deleteMealItem = async (req, res, next) => {
  try {
    const deleted = await deleteMealItemService(req.user.userId, req.params.detailId);
    return successResponse(res, deleted, 'Ítem eliminado con éxito');
  } catch (error) {
    next(error);
  }
};

export const addMealRecipeLog = async (req, res, next) => {
  try {
    const result = await addRecipeToMealService(req.user.userId, req.params.id, req.body);
    return successResponse(res, result, 'Receta registrada con éxito', 201);
  } catch (error) {
    next(error);
  }
};

export const deleteMealRecipeLog = async (req, res, next) => {
  try {
    const deleted = await deleteRecipeLogService(req.user.userId, req.params.recipeLogId);
    return successResponse(res, deleted, 'Receta eliminada con éxito');
  } catch (error) {
    next(error);
  }
};
