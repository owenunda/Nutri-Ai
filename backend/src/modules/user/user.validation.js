import { AppError } from '../../utils/AppError.js';

export const validateUpdateProfileRequest = (req, res, next) => {
  const { age, weight, height, goal } = req.body ?? {};
  const details = [];

  const parsedAge = age !== undefined ? Number(age) : undefined;
  const parsedWeight = weight !== undefined ? Number(weight) : undefined;
  const parsedHeight = height !== undefined ? Number(height) : undefined;

  const hasAtLeastOneField =
    age !== undefined ||
    weight !== undefined ||
    height !== undefined ||
    goal !== undefined;

  if (!hasAtLeastOneField) {
    details.push({
      field: 'body',
      message: 'At least one field must be provided: age, weight, height or goal',
    });
  }

  if (age !== undefined && (!Number.isInteger(parsedAge) || parsedAge < 16 || parsedAge > 120)) {
    details.push({ field: 'age', message: 'Age must be an integer between 16 and 120' });
  }

  if (
    weight !== undefined &&
    (!Number.isFinite(parsedWeight) || parsedWeight <= 0 || parsedWeight > 500)
  ) {
    details.push({ field: 'weight', message: 'Weight must be a number greater than 0' });
  }

  if (
    height !== undefined &&
    (!Number.isFinite(parsedHeight) || parsedHeight <= 0 || parsedHeight > 300)
  ) {
    details.push({ field: 'height', message: 'Height must be a number greater than 0' });
  }

  if (goal !== undefined && (typeof goal !== 'string' || !goal.trim())) {
    details.push({ field: 'goal', message: 'Goal must be a non-empty string' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.profileUpdateData = {
    ...(age !== undefined && { age: parsedAge }),
    ...(weight !== undefined && { weight: parsedWeight }),
    ...(height !== undefined && { height: parsedHeight }),
    ...(goal !== undefined && { goal: goal.trim() }),
  };

  next();
};
