import { AppError } from '../../utils/AppError.js';
import { errorResponse, successResponse } from '../../utils/response.js';
import { localizeError } from '../../i18n/localize.js';
import { sendChatN8n } from '../../utils/n8n.service.js';
import { getFridgeItemsByIdsService } from '../fridge/fridge.service.js';

// La respuesta de n8n es un objeto (type, message, recipe...): la cuota va a su lado.
const withQuota = (result, quota) =>
  result && typeof result === 'object' && !Array.isArray(result) ? { ...result, quota } : result;

export const sendChatMessageController = async (req, res) => {
  try {
    const { message, fridgeItemIds, foodIds } = req.body;
    const { userId, name } = req.user;
    const token = req.headers.authorization?.split(' ')[1];

    if (!message) throw new AppError('Bad request', 400, 'BAD_REQUEST');

    // Los ids se releen de la nevera y del catálogo visible para el usuario
    // autenticado: lo que el cliente mande y no sea suyo nunca llega a n8n.
    const attachedFoods = await getFridgeItemsByIdsService(userId, fridgeItemIds, foodIds);

    const result = await sendChatN8n(message, userId, name, token, attachedFoods, req.lang);
    return successResponse(
      res,
      withQuota(result, req.chatQuota?.quota ?? null),
      'Mensaje enviado correctamente a n8n'
    );
  } catch (error) {
    // Un mensaje sin respuesta no cuenta para el límite del día.
    await req.chatQuota?.refund();
    const { message, details } = localizeError(error, req.lang);
    return errorResponse(res, message, error.code, error.status, details);
  }
};
