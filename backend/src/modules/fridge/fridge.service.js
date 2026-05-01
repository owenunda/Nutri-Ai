import { AppError } from '../../utils/AppError.js';
import { getFridgeByUserIdRepository } from './fridge.repository.js';

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
