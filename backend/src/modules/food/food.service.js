import { findAllFoods, create as createFoodRepository } from './food.repository.js';
import { AppError } from '../../utils/AppError.js';

/**
 * Obtiene la lista de alimentos (Globales y específicos del usuario)
 */
export const getFoods = async (filters) => {
    try {
        return await findAllFoods(filters);
    } catch (error) {
        // Si el error ya es una instancia de AppError, lo lanzamos tal cual
        if (error instanceof AppError) {
            throw error;
        }
        // Si es un error inesperado, lo envolvemos en un AppError 500
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};

export const getFoodModuleStatus = async () => {
    return {
        module: 'food',
        status: 'running'
    };
};


export const createFood = async (foodData) => {
    try {
        // Aquí se puede añadir lógica de negocio extra en el futuro
        // como validar que el nombre no sea ofensivo o verificar duplicados

        return await createFoodRepository(foodData);
    } catch (error) {
        // Manejo consistente de errores
        if (error instanceof AppError) {
            throw error;
        }
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};