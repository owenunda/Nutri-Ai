import { AppError } from '../../utils/AppError.js';

/**
 * Middleware: Se usa en el archivo de rutas (food.routes.js)
 */
export const validateListFoodsQuery = (req, res, next) => {
    const { page, limit } = req.query;
    const details = [];

    const parsedPage = page !== undefined ? Number(page) : null;
    const parsedLimit = limit !== undefined ? Number(limit) : null;

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
        page: parsedPage,
        limit: parsedLimit,
    };

    // ¡CRÍTICO! Sin este next(), el GET se queda cargando
    next();
};

/**
 * Función de utilidad: Se usa dentro del controlador
 */
export const validateCreateFood = (data) => {
    const { name, calories_per_unit, base_unit } = data;

    if (!name || !base_unit || calories_per_unit === undefined) {
        throw new AppError('Missing required fields: name, calories_per_unit, or base_unit', 400, 'VALIDATION_ERROR');
    }

    if (typeof calories_per_unit !== 'number' || calories_per_unit < 0) {
        throw new AppError('Calories must be a non-negative number', 400, 'VALIDATION_ERROR');
    }

    if (typeof name !== 'string' || name.trim() === '') {
        throw new AppError('Name cannot be empty', 400, 'VALIDATION_ERROR');
    }
};

/**
 * Función de utilidad: Se usa dentro del controlador
 */
export const validateUpdateFood = (data) => {
    if (Object.keys(data).length === 0) {
        throw new AppError('At least one field must be provided for update', 400, 'VALIDATION_ERROR');
    }

    if (data.calories_per_unit !== undefined) {
        if (typeof data.calories_per_unit !== 'number' || data.calories_per_unit < 0) {
            throw new AppError('Calories must be a non-negative number', 400, 'VALIDATION_ERROR');
        }
    }

    if (data.name !== undefined && (typeof data.name !== 'string' || data.name.trim() === '')) {
        throw new AppError('Name cannot be empty', 400, 'VALIDATION_ERROR');
    }
};