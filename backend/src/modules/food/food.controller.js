import { successResponse } from '../../utils/response.js';
import { getFoods, getFoodModuleStatus, createFood as createFoodService } from './food.service.js';
import { AppError } from '../../utils/AppError.js';

// Obtener todos los alimentos
export const getAllFoods = async (req, res, next) => {
    try {
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
        // 1. Extraemos con los nombres 
        const { name, calories_per_unit, base_unit } = req.body;
        const userId = req.user.userId;

        // 2. Validación con los nuevos nombres
        if (!name || !base_unit || calories_per_unit === undefined) {
            throw new AppError('Missing required fields: name, calories_per_unit, or base_unit', 400, 'VALIDATION_ERROR');
        }

        // 3. Llamada al servicio
        const foodId = await createFoodService({
            name,
            calories_per_unit,
            base_unit,
            userId
        });

        return successResponse(res, { foodId }, 'Food created successfully', 201);
    } catch (error) {
        next(error);
    }
};