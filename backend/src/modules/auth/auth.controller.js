import { successResponse } from '../../utils/response.js';
import { getAuthModuleStatus, loginUser, registerUser } from './auth.service.js';

export const getAuthHealth = async (req, res, next) => {
  try {
    const status = await getAuthModuleStatus();
    return successResponse(res, status, 'Auth module is running', 200);
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const authData = await loginUser(req.loginData);
    return successResponse(res, authData, 'Login successful', 200);
  } catch (error) {
    next(error);
  }
};

export const register = async (req, res, next) => {
  try {
    const user = await registerUser(req.registerData);
    return successResponse(res, user, 'User registered successfully', 201);
  } catch (error) {
    next(error);
  }
};
