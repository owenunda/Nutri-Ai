import { AppError } from '../../utils/AppError.js';

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const validateAuthHealthRequest = (req, res, next) => {
  next();
};

export const validateLoginRequest = (req, res, next) => {
  const { email, password } = req.body ?? {};
  const details = [];

  if (!email || typeof email !== 'string' || !email.trim()) {
    details.push({ field: 'email', message: 'Email is required' });
  } else if (!emailRegex.test(email.trim())) {
    details.push({ field: 'email', message: 'Email format is invalid' });
  }

  if (!password || typeof password !== 'string' || !password.trim()) {
    details.push({ field: 'password', message: 'Password is required' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.loginData = {
    email: email.trim().toLowerCase(),
    password,
  };

  next();
};

export const validateRegisterRequest = (req, res, next) => {
  const { name, email, password, goal } = req.body ?? {};
  const details = [];

  if (!name || typeof name !== 'string' || !name.trim()) {
    details.push({ field: 'name', message: 'Name is required' });
  }

  if (!email || typeof email !== 'string' || !email.trim()) {
    details.push({ field: 'email', message: 'Email is required' });
  } else if (!emailRegex.test(email.trim())) {
    details.push({ field: 'email', message: 'Email format is invalid' });
  }

  if (!password || typeof password !== 'string' || !password.trim()) {
    details.push({ field: 'password', message: 'Password is required' });
  } else if (password.trim().length < 6) {
    details.push({ field: 'password', message: 'Password must be at least 6 characters' });
  }

  if (goal !== undefined && goal !== null && typeof goal !== 'string') {
    details.push({ field: 'goal', message: 'Goal must be a string' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.registerData = {
    name: name.trim(),
    email: email.trim().toLowerCase(),
    password,
    goal: goal?.trim() || null,
  };

  next();
};
