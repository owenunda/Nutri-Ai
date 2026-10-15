import { successResponse } from '../../utils/response.js';
import {
  forgotPassword,
  getAuthModuleStatus,
  linkGoogleAccount,
  loginUser,
  loginWithGoogle,
  registerUser,
  resendVerification,
  resetPassword,
  verifyEmail,
} from './auth.service.js';

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
    const authData = await loginUser({ ...req.loginData, lang: req.lang });
    return successResponse(res, authData, 'Login successful', 200);
  } catch (error) {
    next(error);
  }
};

export const register = async (req, res, next) => {
  try {
    const user = await registerUser({ ...req.registerData, lang: req.lang });
    return successResponse(res, user, 'User registered successfully', 201);
  } catch (error) {
    next(error);
  }
};

export const googleLogin = async (req, res, next) => {
  try {
    const authData = await loginWithGoogle(req.googleLoginData);
    return successResponse(res, authData, 'Login successful', 200);
  } catch (error) {
    next(error);
  }
};

export const googleLink = async (req, res, next) => {
  try {
    const authData = await linkGoogleAccount(req.googleLinkData);
    return successResponse(res, authData, 'Account linked successfully', 200);
  } catch (error) {
    next(error);
  }
};

export const verifyEmailController = async (req, res, next) => {
  try {
    const authData = await verifyEmail(req.verifyEmailData);
    return successResponse(res, authData, 'Email verified successfully', 200);
  } catch (error) {
    next(error);
  }
};

// Respuesta genérica: no revela si el correo tiene cuenta.
const CODE_SENT_MESSAGE = 'Si el correo tiene una cuenta, te enviamos un código.';

export const resendVerificationController = async (req, res, next) => {
  try {
    await resendVerification({ ...req.emailData, lang: req.lang });
    return successResponse(res, null, CODE_SENT_MESSAGE, 200);
  } catch (error) {
    next(error);
  }
};

export const forgotPasswordController = async (req, res, next) => {
  try {
    await forgotPassword({ ...req.emailData, lang: req.lang });
    return successResponse(res, null, CODE_SENT_MESSAGE, 200);
  } catch (error) {
    next(error);
  }
};

export const resetPasswordController = async (req, res, next) => {
  try {
    await resetPassword(req.resetPasswordData);
    return successResponse(res, null, 'Password reset successfully', 200);
  } catch (error) {
    next(error);
  }
};
