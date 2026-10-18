import axios from 'axios';
import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const BASE_URL = 'https://api.revenuecat.com/v1';

const providerError = () =>
  new AppError(
    'No pudimos confirmar tu suscripción. Intenta de nuevo en unos minutos.',
    502,
    'SUBSCRIPTION_PROVIDER_ERROR'
  );

/**
 * Estado de un usuario en RevenueCat. El app user id es nuestro user_id.
 * @returns {Promise<Object>} el `subscriber` de la respuesta.
 */
export const fetchSubscriber = async (appUserId) => {
  const { secretKey } = config.revenuecat;
  if (!secretKey) {
    console.error('[revenuecat] falta REVENUECAT_SECRET_KEY');
    throw providerError();
  }
  let data;
  try {
    ({ data } = await axios.get(`${BASE_URL}/subscribers/${encodeURIComponent(appUserId)}`, {
      headers: { Authorization: `Bearer ${secretKey}` },
      timeout: 10_000,
    }));
  } catch (error) {
    console.error('[revenuecat] no se pudo leer el suscriptor:', error.response?.status ?? '', error.message);
    throw providerError();
  }
  // Una respuesta sin suscriptor no es "sin suscripción": nunca debe bajar a un usuario de PRO.
  if (!data?.subscriber) {
    console.error('[revenuecat] respuesta sin suscriptor');
    throw providerError();
  }
  return data.subscriber;
};
