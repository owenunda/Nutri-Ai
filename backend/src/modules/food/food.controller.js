import { successResponse } from '../../utils/response.js';
import {
    getFoods,
    getFoodModuleStatus,
    createFood as createFoodService,
    updateFoodItem,
    deactivateFoodItem,
    matchFoods as matchFoodsService
} from './food.service.js';

// Obtener todos los alimentos
export const getAllFoods = async (req, res, next) => {
    try {
        // req.foodFilters viene del middleware de validación
        const foods = await getFoods({
            userId: req.user.userId,
            page: req.foodFilters?.page ?? null,
            limit: req.foodFilters?.limit ?? null,
        });
        return successResponse(res, foods, 'Foods retrieved successfully', 200);
    } catch (error) {
        next(error);
    }
};

// Salud del módulo
export const getFoodHealth = async (req, res, next) => {
    try {
        const status = await getFoodModuleStatus();
        return successResponse(res, status, 'Food module is running', 200);
    } catch (error) {
        next(error);
    }
};

// Crear alimento 
export const createFood = async (req, res, next) => {
    try {
        const foodData = {
            name: req.body.name,
            calories_per_unit: req.body.calories_per_unit ?? req.body.caloriesPerUnit,
            base_unit: req.body.base_unit ?? req.body.baseUnit,
            userId: req.user.userId,
        };
        const foodId = await createFoodService(foodData);
        return successResponse(res, { foodId }, 'Food created successfully', 201);
    } catch (error) {
        next(error);
    }
};

// Editar alimento
export const updateFood = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const updateData = {};

        if (req.body.name !== undefined) {
            updateData.name = req.body.name;
        }

        if (req.body.calories_per_unit !== undefined || req.body.caloriesPerUnit !== undefined) {
            updateData.calories_per_unit = req.body.calories_per_unit ?? req.body.caloriesPerUnit;
        }

        if (req.body.base_unit !== undefined || req.body.baseUnit !== undefined) {
            updateData.base_unit = req.body.base_unit ?? req.body.baseUnit;
        }

        const updatedFood = await updateFoodItem(id, userId, updateData);
        return successResponse(res, updatedFood, 'Food updated successfully', 200);
    } catch (error) {
        next(error);
    }
};

// Desactivar alimento
export const deleteFood = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        await deactivateFoodItem(id, userId);
        return successResponse(res, null, 'Food deactivated successfully', 200);
    } catch (error) {
        next(error);
    }
};


export const matchFoods = async (req, res, next) => {
    try {
        const ingredients = Array.isArray(req.body) ? req.body : req.body.ingredients;
        console.log(ingredients);
        const userId = req.user.userId;
        const foods = await matchFoodsService(ingredients, userId);
        return successResponse(res, foods, 'Foods matched successfully', 200);
    } catch (error) {
        next(error);
    }
}