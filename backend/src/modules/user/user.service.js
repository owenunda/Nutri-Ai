import bcrypt from 'bcrypt';
import { AppError } from '../../utils/AppError.js';
import { logEventService } from '../events/events.service.js';
import { verifyGoogleIdToken } from '../auth/google.verifier.js';
import {
  createPhysicalRecord,
  deleteUserAccountData,
  findUserCredentialsById,
  findPhysicalHistoryByUserId,
  findUserProfileById,
  setPasswordIfMissing,
  updateUserProfileData,
} from './user.repository.js';
import { computeEffectivePlan } from '../subscription/effectivePlan.js';

const SALT_ROUNDS = 10;

// El perfil dice de dónde viene el PRO, sin exponer las columnas internas.
const withProSource = ({ giftPro, giftProUntil, storeExpiresAt, ...profile }) => ({
  ...profile,
  proSource: computeEffectivePlan({ giftPro, giftProUntil, storeExpiresAt }).proSource,
});

export const getUserProfile = async (userId) => {
  try {
    const user = await findUserProfileById(userId);

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return withProSource(user);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const savePhysicalRecord = async (userId, physicalData) => {
  try {
    const physicalRecord = await createPhysicalRecord(userId, physicalData);

    if (!physicalRecord) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return physicalRecord;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const getPhysicalHistory = async (userId) => {
  try {
    const user = await findUserProfileById(userId);

    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return await findPhysicalHistoryByUserId(userId);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

export const updateUserProfile = async (userId, profileData) => {
  try {
    const updatedUser = await updateUserProfileData(userId, profileData);

    if (!updatedUser) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return withProSource(updatedUser);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

const missingField = (field, message) =>
  new AppError('Validation error', 400, 'VALIDATION_ERROR', [{ field, message }]);

// Se pide la contraseña aunque el token sea válido: un teléfono desbloqueado
// en manos de otro no debería bastar para borrar la cuenta. Quien no tiene
// contraseña confirma volviendo a autenticarse con Google.
// Los rechazos son 403 y no 401: el token es válido, y la app cierra sesión ante un 401.
const confirmAccountOwnership = async (credentials, { password, googleIdToken }) => {
  if (credentials.passwordHash) {
    if (!password) {
      throw missingField('password', 'Password is required');
    }

    const isPasswordValid = await bcrypt.compare(password, credentials.passwordHash);
    if (!isPasswordValid) {
      throw new AppError('Contraseña incorrecta', 403, 'INVALID_PASSWORD');
    }
    return;
  }

  if (!googleIdToken) {
    throw missingField('googleIdToken', 'Google idToken is required');
  }

  let profile;
  try {
    profile = await verifyGoogleIdToken(googleIdToken);
  } catch (error) {
    if (error?.code === 'INVALID_GOOGLE_TOKEN') {
      throw new AppError(error.message, 403, 'INVALID_GOOGLE_TOKEN');
    }
    throw error;
  }

  if (profile.sub !== credentials.googleSub) {
    throw new AppError(
      'Esa cuenta de Google no corresponde a este perfil.',
      403,
      'GOOGLE_ACCOUNT_MISMATCH'
    );
  }
};

export const deleteUserAccount = async (userId, confirmation) => {
  try {
    const credentials = await findUserCredentialsById(userId);

    if (!credentials) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    await confirmAccountOwnership(credentials, confirmation);

    const deleted = await deleteUserAccountData(userId);

    if (!deleted) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    // Sin userId ni correo: el evento solo cuenta que hubo un borrado.
    await logEventService({
      eventType: 'ACCOUNT_DELETED',
      category: 'AUTH',
      userId: null,
      metadata: {},
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};

// Crea la contraseña de una cuenta que solo entraba con Google. Cambiar una
// contraseña que ya existe pediría la actual, así que aquí se rechaza.
export const setUserPassword = async (userId, password) => {
  try {
    const credentials = await findUserCredentialsById(userId);

    if (!credentials) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const alreadySet = new AppError(
      'Tu cuenta ya tiene contraseña.',
      409,
      'PASSWORD_ALREADY_SET'
    );
    if (credentials.passwordHash) {
      throw alreadySet;
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const updated = await setPasswordIfMissing(userId, passwordHash);
    if (!updated) {
      throw alreadySet;
    }

    await logEventService({
      eventType: 'PASSWORD_SET',
      category: 'AUTH',
      userId,
      metadata: {},
    });
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    throw new AppError(error.message, 500, 'USER_SERVICE_ERROR');
  }
};
