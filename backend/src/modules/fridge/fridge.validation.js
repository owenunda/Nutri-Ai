import { AppError } from '../../utils/AppError.js';

/**
 * Middleware: Se usa en el archivo de rutas (fridge.routes.js)
 */
export const validateAddFridgeItem = (req, res, next) => {
    if (!req.body || typeof req.body !== 'object') {
        return next(new AppError('Request body is required and must be JSON', 400, 'VALIDATION_ERROR'));
    }

    const { foodId, quantity, unit } = req.body;

    if (!foodId || !quantity || !unit) {
        return next(new AppError('Missing required fields: foodId, quantity, or unit', 400, 'VALIDATION_ERROR'));
    }

    const parsedFoodId = Number(foodId);
    const parsedQuantity = Number(quantity);

    if (!Number.isInteger(parsedFoodId) || parsedFoodId <= 0) {
        return next(new AppError('foodId must be a positive integer', 400, 'VALIDATION_ERROR'));
    }

    if (typeof parsedQuantity !== 'number' || parsedQuantity <= 0) {
        return next(new AppError('quantity must be a number greater than 0', 400, 'VALIDATION_ERROR'));
    }

    if (typeof unit !== 'string' || unit.trim() === '') {
        return next(new AppError('unit cannot be empty', 400, 'VALIDATION_ERROR'));
    }

    req.fridgeItemData = {
        foodId: parsedFoodId,
        quantity: parsedQuantity,
        unit: unit.trim(),
    };

    next();
};

/**
 * Middleware: Se usa en el archivo de rutas (fridge.routes.js) para actualizar items
 */
export const validateUpdateFridgeItem = (req, res, next) => {
    if (!req.body || typeof req.body !== 'object') {
        return next(new AppError('Request body is required and must be JSON', 400, 'VALIDATION_ERROR'));
    }

    const { quantity } = req.body;

    if (quantity === undefined) {
        return next(new AppError('quantity is required', 400, 'VALIDATION_ERROR'));
    }

    const parsedQuantity = Number(quantity);

    if (typeof parsedQuantity !== 'number' || parsedQuantity < 0) {
        return next(new AppError('quantity must be a number greater than or equal to 0', 400, 'VALIDATION_ERROR'));
    }

    const itemId = Number(req.params.id);
    if (!Number.isInteger(itemId) || itemId <= 0) {
        return next(new AppError('Item ID must be a positive integer', 400, 'VALIDATION_ERROR'));
    }

    req.fridgeUpdateData = {
        itemId,
        quantity: parsedQuantity,
    };

    next();
};