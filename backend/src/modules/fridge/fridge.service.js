import { AppError } from '../../utils/AppError.js';
import { addFridgeItemRepository, addOrUpdateFridgeItemRepository, checkFoodExistsRepository, createFridgeRepository, getFridgeByUserIdRepository } from './fridge.repository.js';

export const getFridge = async (userId) => {
    try {
        const fridge = await getFridgeByUserIdRepository(userId);

        if (!fridge) {
            return {
                fridgeId: null,
                userId,
                createdAt: null,
                updatedAt: null,
                items: [],
            };
        }

        return fridge;
    } catch (error) {
        if (error instanceof AppError) {
            throw error;
        }

        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};

export const getFridgeModuleStatus = async () => {
    return {
        module: 'fridge',
        status: 'running',
    };
};

// Crea la nevera del usuario, validando que no exista una previa
export const createFridgeService = async (userId) => {
    try {
        const existing = await getFridgeByUserIdRepository(userId);

        if (existing) {
            throw new AppError('User already has a fridge', 409, 'FRIDGE_ALREADY_EXISTS');
        }

        const fridge = await createFridgeRepository(userId);
        return fridge;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};

// Agrega automáticamente un alimento recién creado a la nevera del usuario
export const addItemToFridgeService = async (userId, foodId, unit) => {
    try {
        const fridge = await getFridgeByUserIdRepository(userId);

        if (!fridge) {
            throw new AppError('Fridge not found for this user', 404, 'FRIDGE_NOT_FOUND');
        }

        const item = await addFridgeItemRepository(fridge.fridgeId, foodId, unit);
        return item;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};

// Agrega o actualiza un item en la nevera del usuario con cantidad específica
export const addItemToFridgeWithQuantityService = async (userId, foodId, quantity, unit) => {
    try {
        // Verificar que el alimento existe y está activo
        const food = await checkFoodExistsRepository(foodId);
        if (!food) {
            throw new AppError('Food item not found or inactive', 404, 'FOOD_NOT_FOUND');
        }

        // Obtener la nevera del usuario
        const fridge = await getFridgeByUserIdRepository(userId);
        if (!fridge) {
            throw new AppError('Fridge not found for this user', 404, 'FRIDGE_NOT_FOUND');
        }

        // Agregar o actualizar el item
        const item = await addOrUpdateFridgeItemRepository(fridge.fridgeId, foodId, quantity, unit);
        return item;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};
