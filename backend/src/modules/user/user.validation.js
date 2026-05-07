import { AppError } from '../../utils/AppError.js';

export const validateCreatePhysicalRecordRequest = (req, res, next) => {
  const { height, weight } = req.body ?? {};
  const details = [];

  const parsedHeight = height !== undefined ? Number(height) : undefined;
  const parsedWeight = weight !== undefined ? Number(weight) : undefined;

  if (height === undefined) {
    details.push({ field: 'height', message: 'Height is required' });
  } else if (!Number.isFinite(parsedHeight) || parsedHeight <= 0 || parsedHeight > 300) {
    details.push({ field: 'height', message: 'Height must be a number greater than 0' });
  }

  if (weight === undefined) {
    details.push({ field: 'weight', message: 'Weight is required' });
  } else if (!Number.isFinite(parsedWeight) || parsedWeight <= 0 || parsedWeight > 500) {
    details.push({ field: 'weight', message: 'Weight must be a number greater than 0' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.physicalRecordData = {
    height: parsedHeight,
    weight: parsedWeight,
  };

  next();
};
