import { successResponse } from '../../utils/response.js';
import { getFoods, getFoodModuleStatus } from './food.service.js';

// El controller recibe la peticion HTTP y devuelve la respuesta

export const getAllFoods = async (req, res, next) => {
    try {
        const foods = await getFoods(req.foodFilters ?? {});
        return successResponse(res, foods, 'Foods retrieved successfully', 200);
    } catch (error) {
        next(error);
    }
};

export const getFoodHealth = async (req, res, next) => {
    try {
        const status = await getFoodModuleStatus();
        return successResponse(res, status, 'Food module is running', 200);
    } catch (error) {
        next(error);
    }
};
