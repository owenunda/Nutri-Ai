import { successResponse } from '../../utils/response.js';
import { getFridge, getFridgeModuleStatus } from './fridge.service.js';

export const getFridgeItems = async (req, res, next) => {
    try {
        const userId = Number(req.user.userId);
        const fridge = await getFridge(userId);
        return successResponse(res, fridge, 'Fridge retrieved successfully', 200);
    } catch (error) {
        next(error);
    }
};

export const getFridgeHealth = async (req, res, next) => {
    try {
        const status = await getFridgeModuleStatus();
        return successResponse(res, status, 'Fridge module is running', 200);
    } catch (error) {
        next(error);
    }
};
