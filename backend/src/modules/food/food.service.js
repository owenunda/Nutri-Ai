import { findAllFoods } from './food.repository.js';
import { AppError } from '../../utils/AppError.js';

export const getFoods = async (filters) => {
    try {
        return await findAllFoods(filters);
    } catch (error) {
        if (error instanceof AppError) {
            throw error;
        }
        throw new AppError(error.message, 500, 'FOOD_SERVICE_ERROR');
    }
};

export const getFoodModuleStatus = async () => {
    return {
        module: 'food',
        status: 'running'
    };
};
