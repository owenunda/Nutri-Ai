import { OAuth2Client } from 'google-auth-library';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const client = new OAuth2Client();

const invalidToken = () =>
  new AppError('No se pudo verificar tu cuenta de Google.', 401, 'INVALID_GOOGLE_TOKEN');

// Comprueba firma, expiración y que el token se emitió para alguno de
// nuestros client IDs (Web, Android o iOS).
export const verifyGoogleIdToken = async (idToken) => {
  const audience = config.google.clientIds;

  if (audience.length === 0) {
    throw new AppError('Google client IDs are not configured', 500, 'AUTH_CONFIG_ERROR');
  }

  let payload;
  try {
    const ticket = await client.verifyIdToken({ idToken, audience });
    payload = ticket.getPayload();
  } catch {
    throw invalidToken();
  }

  if (!payload?.sub || !payload?.email) {
    throw invalidToken();
  }

  return {
    sub: payload.sub,
    email: payload.email.toLowerCase(),
    emailVerified: payload.email_verified === true,
    name: payload.name ?? null,
  };
};
