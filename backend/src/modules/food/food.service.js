import * as foodRepository from './food.repository.js';
import { AppError } from '../../utils/AppError.js';
import { validateCreateFood, validateUpdateFood } from './food.validation.js';
import { addItemToFridgeService } from '../fridge/fridge.service.js';
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
        validateCreateFood(foodData);

        // Verificar si el alimento ya existe (global o creado por el usuario)
        const existingFood = await foodRepository.findFoodByName(foodData.name, foodData.userId);
        if (existingFood) {
            throw new AppError('Food item with this name already exists', 409, 'DUPLICATE_FOOD');
        }

        // En el futuro se pueden añadir validaciones de negocio aquí
        const foodId = await foodRepository.create(foodData);

        // Agregar el alimento a la nevera del usuario
        await addItemToFridgeService(foodData.userId, foodId, foodData.base_unit);

        return foodId;
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

        validateUpdateFood(updateData);

        // Si se está actualizando el nombre, verificar duplicados
        if (updateData.name) {
            const existingFood = await foodRepository.findFoodByName(updateData.name, userId);
            if (existingFood && existingFood.foodId !== foodId) {
                throw new AppError('Food item with this name already exists', 409, 'DUPLICATE_FOOD');
            }
        }

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

/**
 * Desactiva un alimento existente validando propiedad
 */
export const deactivateFoodItem = async (foodId, userId) => {
    try {
        // 1. Buscamos el alimento usando el ID de la URL
        const food = await foodRepository.getFoodById(foodId);

        // Caso: No existe
        if (!food) {
            throw new AppError('Food item not found', 404, 'NOT_FOUND');
        }

        // Caso: El usuario no es el dueño
        if (food.createdByUserId !== userId) {
            throw new AppError('Unauthorized: You can only deactivate your own food items', 403, 'FORBIDDEN');
        }

        // Caso: Es global, no se puede desactivar
        if (food.isGlobal) {
            throw new AppError('Cannot deactivate global food items', 403, 'FORBIDDEN');
        }

        // Caso: Ya está desactivado
        if (!food.isActive) {
            throw new AppError('Food item is already deactivated', 400, 'BAD_REQUEST');
        }

        // Todo OK, procedemos a desactivar
        return await foodRepository.deactivateFood(foodId);

    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};