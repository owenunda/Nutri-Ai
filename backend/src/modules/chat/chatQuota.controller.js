import { successResponse } from '../../utils/response.js';
import { getChatQuota } from './chatQuota.service.js';

/** Cuota de hoy del Chef IA, sin consumir mensajes. */
export const getChatQuotaController = async (req, res, next) => {
  try {
    const quota = await getChatQuota(req.user);
    return successResponse(res, quota, 'Cuota del chat obtenida correctamente');
  } catch (error) {
    next(error);
  }
};
