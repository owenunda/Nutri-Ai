import { successResponse } from '../../utils/response.js';
import {
    getFoods,
    getFoodModuleStatus,
    createFood as createFoodService,
    updateFoodItem
} from './food.service.js';
import { validateUpdateFood, validateCreateFood } from './food.validation.js';

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
        const foodData = { ...req.body, userId: req.user.userId };

        // Al ser función pura, si falla lanza el error directo al catch
        validateCreateFood(foodData);

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
        const updateData = req.body;

        validateUpdateFood(updateData);

        const updatedFood = await updateFoodItem(id, userId, updateData);
        return successResponse(res, updatedFood, 'Food updated successfully', 200);
    } catch (error) {
        next(error);
    }
};