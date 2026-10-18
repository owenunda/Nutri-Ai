import { successResponse } from '../../utils/response.js';
import { handleWebhookEvent, syncUser } from './subscription.service.js';

const handle = (run, message) => async (req, res, next) => {
  try {
    return successResponse(res, await run(req), message);
  } catch (error) {
    next(error);
  }
};

export const syncSubscription = handle((req) => syncUser(req.user.userId), 'Suscripción sincronizada');
export const receiveWebhook = handle((req) => handleWebhookEvent(req.body?.event), 'Evento procesado');
