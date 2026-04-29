import * as foodRepository from './food.repository.js';
import { AppError } from '../../utils/AppError.js';

/**
 * Obtiene la lista de alimentos (Globales y específicos del usuario)
 */
export const getFoods = async (filters) => {
    try {
        return await foodRepository.findAllFoods(filters);
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};

/**
 * Verifica el estado del módulo
 */
export const getFoodModuleStatus = async () => {
    return {
        module: 'food',
        status: 'running'
    };
};

/**
 * Crea un nuevo alimento
 */
export const createFood = async (foodData) => {
    try {
        // En el futuro se pueden añadir validaciones de negocio aquí
        return await foodRepository.create(foodData);
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};

/**
 * Actualiza un alimento existente validando propiedad
 */
export const updateFoodItem = async (foodId, userId, updateData) => {
    try {
        // 1. Buscamos el alimento usando el ID de la URL
        const food = await foodRepository.getFoodById(foodId);

        // Caso 4 de Bruno: No existe
        if (!food) {
            throw new AppError('Food item not found', 404, 'NOT_FOUND');
        }

        // Caso 2 de Bruno: El usuario no es el dueño
        if (food.createdByUserId !== userId) {
            throw new AppError('Unauthorized: You can only edit your own food items', 403, 'FORBIDDEN');
        }

        // Caso 1 de Bruno: Todo OK, procedemos a actualizar
        return await foodRepository.updateFood(foodId, updateData);

    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};