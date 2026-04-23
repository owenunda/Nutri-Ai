import { AppError } from '../../utils/AppError.js';

// Este archivo queda listo para futuras validaciones del modulo.


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
