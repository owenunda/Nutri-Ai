import { AppError } from '../../utils/AppError.js';

// Este archivo queda listo para futuras validaciones del modulo.
export const validateListFoodsQuery = (req, res, next) => {
    const { userId, page, limit } = req.query;
    const details = [];

    const parsedUserId = userId !== undefined ? Number(userId) : null;
    const parsedPage = page !== undefined ? Number(page) : null;
    const parsedLimit = limit !== undefined ? Number(limit) : null;

    if (userId !== undefined && (!Number.isInteger(parsedUserId) || parsedUserId <= 0)) {
        details.push({ field: 'userId', message: 'userId must be a positive integer' });
    }

    if (page !== undefined && (!Number.isInteger(parsedPage) || parsedPage <= 0)) {
        details.push({ field: 'page', message: 'page must be a positive integer' });
    }

    if (limit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit <= 0)) {
        details.push({ field: 'limit', message: 'limit must be a positive integer' });
    }

    if ((page !== undefined && limit === undefined) || (page === undefined && limit !== undefined)) {
        details.push({ field: 'pagination', message: 'page and limit must be sent together' });
    }

    if (details.length > 0) {
        return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
    }

    req.foodFilters = {
        userId: parsedUserId,
        page: parsedPage,
        limit: parsedLimit,
    };

    next();
};
//-------------------------------------------------
export const validateCreateFood = (req, res, next) => {
    const { name, caloriesPerUnit, baseUnit } = req.body;
    const details = [];

    if (!name) {
        details.push({ field: 'name', message: 'The name is required' });
    }

    if (caloriesPerUnit === undefined || caloriesPerUnit === null) {
        details.push({ field: 'caloriesPerUnit', message: 'Calories per unit is required' });
    }

    if (!baseUnit) {
        details.push({ field: 'baseUnit', message: 'The base unit is required' });
    }

    if (details.length > 0) {
        return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
    }

    next();
};
