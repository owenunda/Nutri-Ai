import { consumeChatQuota } from '../modules/chat/chatQuota.service.js';
import { errorResponse } from '../utils/response.js';
import { localizeError } from '../i18n/localize.js';

/**
 * Límite diario del Chef IA. Va después de chatRateLimit en POST /n8n/chat.
 * Deja en req.chatQuota la cuota ya descontada y refund() para devolver el
 * mensaje si n8n falla.
 */
export const chatDailyQuota = async (req, res, next) => {
  try {
    const { allowed, quota, refund } = await consumeChatQuota(req.user);
    if (allowed) {
      req.chatQuota = { quota, refund };
      return next();
    }

    const fairUse = quota.unlimited;
    const code = fairUse ? 'CHAT_FAIR_USE_LIMIT' : 'CHAT_DAILY_LIMIT';
    const source = fairUse
      ? 'Llegaste al límite de uso justo de hoy. Vuelve mañana.'
      : quota.limit === 1
        ? 'Usaste tu 1 mensaje de hoy con el Chef IA.'
        : `Usaste tus ${quota.limit} mensajes de hoy con el Chef IA.`;
    const { message } = localizeError(
      { code, message: source, params: { limit: quota.limit } },
      req.lang
    );
    return errorResponse(res, message, code, 429, [], { quota });
  } catch (error) {
    return next(error);
  }
};
