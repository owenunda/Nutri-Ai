import {
  createMealRecordRepository,
  addItemsToMealRepository,
  findMealRecordByUserAndDate,
  findMealRecordOwnerRepository,
  getDayMealsRepository,
  deleteMealItemRepository,
} from './meal.repository.js';
import { checkFoodsExist } from '../food/food.repository.js';
import { checkRecipesExist } from '../recipe/recipe.repository.js';
import { AppError } from '../../utils/AppError.js';
import { resolveDateParam } from '../../utils/date.js';

const MEAL_TYPES = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'];

export const createMealService = async (userId, date) => {
  try {
    const mealDate = resolveDateParam(date);

    const existing = await findMealRecordByUserAndDate(userId, mealDate);
    if (existing) {
      return existing;
    }

    const mealRecord = await createMealRecordRepository(userId, mealDate);
    return mealRecord;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};

export const addItemsToMealService = async (userId, mealRecordId, items) => {
  try {
    if (!Array.isArray(items) || items.length === 0) {
      throw new AppError('Se requiere una lista de ítems', 400, 'ITEMS_REQUIRED');
    }

    const ownerId = await findMealRecordOwnerRepository(mealRecordId);
    if (ownerId === null || Number(ownerId) !== Number(userId)) {
      throw new AppError('Registro de comida no encontrado', 404, 'MEAL_RECORD_NOT_FOUND');
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
      item.meal_type = item.meal_type ?? 'SNACK';
      if (!MEAL_TYPES.includes(item.meal_type)) {
        throw new AppError(`meal_type debe ser uno de: ${MEAL_TYPES.join(', ')}`, 400, 'INVALID_MEAL_TYPE');
      }
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

export const getDayMealsService = async (userId, date) => {
  try {
    const day = resolveDateParam(date);
    const rows = await getDayMealsRepository(userId, day);
    const meals = Object.fromEntries(
      MEAL_TYPES.map((type) => [type, { totalCalories: 0, items: [] }])
    );
    for (const row of rows) {
      const { mealType, ...item } = row;
      const group = meals[mealType] ?? meals.SNACK;
      group.items.push(item);
      group.totalCalories += item.calories;
    }
    const totalCalories = Object.values(meals).reduce((sum, m) => sum + m.totalCalories, 0);
    return { date: day, totalCalories, meals };
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};

export const deleteMealItemService = async (userId, detailId) => {
  try {
    const id = Number(detailId);
    if (!Number.isInteger(id) || id <= 0) {
      throw new AppError('detailId debe ser un entero positivo', 400, 'VALIDATION_ERROR');
    }
    const deleted = await deleteMealItemRepository(userId, id);
    if (!deleted) {
      throw new AppError('Ítem no encontrado', 404, 'MEAL_ITEM_NOT_FOUND');
    }
    return deleted;
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(error.message, 500, 'MEAL_SERVICE_ERROR');
  }
};
