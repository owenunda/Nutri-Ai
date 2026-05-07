import { createMealService, addItemsToMealService, addRecipesToMealService } from './meal.service.js';
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
