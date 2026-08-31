import { AppError } from '../../utils/AppError.js';
import { addFridgeItemRepository, findFridgeItemsByIdsRepository, addOrUpdateFridgeItemRepository, checkFoodExistsRepository, createFridgeRepository, getFridgeByUserIdRepository, updateFridgeItemRepository, deleteFridgeItemRepository } from './fridge.repository.js';

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

// Actualiza la cantidad de un item en la nevera del usuario
export const updateFridgeItemService = async (userId, itemId, quantity) => {
    try {
        // Actualizar el item, verificando que pertenezca al usuario
        const updatedItem = await updateFridgeItemRepository(itemId, userId, quantity);

        if (!updatedItem) {
            throw new AppError('Fridge item not found or does not belong to user', 404, 'FRIDGE_ITEM_NOT_FOUND');
        }

        return updatedItem;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};

// Elimina un item de la nevera del usuario y desactiva el alimento si es personalizado
export const deleteFridgeItemService = async (userId, itemId) => {
    try {
        // Eliminar el item y desactivar el food si corresponde
        const deletedItem = await deleteFridgeItemRepository(itemId, userId);

        if (!deletedItem) {
            throw new AppError('Fridge item not found or does not belong to user', 404, 'FRIDGE_ITEM_NOT_FOUND');
        }

        return deletedItem;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};

const MAX_ATTACHED_FOODS = 20;

// El prompt del chef trata la cantidad como techo ("nunca una cantidad mayor a
// la disponible"), así que un 0 le prohibiría usar el alimento — justo lo
// contrario de lo que pidió el usuario al adjuntarlo. matchFoods ya resuelve
// esto igual, con `quantity ?? 1`.
const normalizeQuantity = (quantity) => {
    const value = Number(quantity);
    return Number.isFinite(value) && value > 0 ? value : 1;
};

export const getFridgeItemsByIdsService = async (userId, fridgeItemIds) => {
    try {
        const ids = (Array.isArray(fridgeItemIds) ? fridgeItemIds : [])
            .map(Number)
            .filter(Number.isInteger)
            .slice(0, MAX_ATTACHED_FOODS);

        if (ids.length === 0) {
            return [];
        }

        const items = await findFridgeItemsByIdsRepository(userId, ids);

        return items.map((item) => ({
            ...item,
            quantity: normalizeQuantity(item.quantity),
            caloriesPerUnit: Number(item.caloriesPerUnit),
        }));
    } catch (error) {
        if (error instanceof AppError) {
            throw error;
        }

        throw new AppError(error.message, 500, 'FRIDGE_SERVICE_ERROR');
    }
};
