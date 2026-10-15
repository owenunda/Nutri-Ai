import { AppError } from '../../utils/AppError.js';

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const goalSeparatorRegex = /[,;|\n]/;

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

  if (goal !== undefined && goal !== null) {
    if (typeof goal !== 'string' || !goal.trim()) {
      details.push({ field: 'goal', message: 'Goal must be a non-empty string' });
    } else if (goalSeparatorRegex.test(goal.trim())) {
      details.push({ field: 'goal', message: 'Goal must contain a single value' });
    }
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

export const validateGoogleLoginRequest = (req, res, next) => {
  const { idToken } = req.body ?? {};

  if (typeof idToken !== 'string' || !idToken.trim()) {
    return next(
      new AppError('Validation error', 400, 'VALIDATION_ERROR', [
        { field: 'idToken', message: 'Google idToken is required' },
      ])
    );
  }

  req.googleLoginData = { idToken: idToken.trim() };
  next();
};

export const validateGoogleLinkRequest = (req, res, next) => {
  const { idToken, password } = req.body ?? {};
  const details = [];

  if (typeof idToken !== 'string' || !idToken.trim()) {
    details.push({ field: 'idToken', message: 'Google idToken is required' });
  }
  if (typeof password !== 'string' || password.length === 0) {
    details.push({ field: 'password', message: 'Password is required' });
  }

  if (details.length > 0) {
    return next(new AppError('Validation error', 400, 'VALIDATION_ERROR', details));
  }

  req.googleLinkData = { idToken: idToken.trim(), password };
  next();
};
