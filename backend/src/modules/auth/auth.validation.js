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
