import { config } from '../config/env_config.js';
import axios from 'axios';
import { AppError } from './AppError.js';

const URL_WEBHOOK = config.node_env === "development" ? config.n8n.url_dev : config.n8n.url_pro;
if (!URL_WEBHOOK) {
  throw new AppError("URL del webhook de n8n no está configurada", 500, "N8N_CONFIG_ERROR");
}

export const sendChatN8n = async (message, userId, userName, token, attachedFoods = []) => {
  try {
    const payload = {
      message,
      userId,
      name: userName,
      token,
      attachedFoods,
    };
    const response = await axios.post(URL_WEBHOOK, payload);
    return response.data;
  } catch (error) {
    console.error("Error al enviar mensaje a n8n:", error.response?.data || error.message);
    throw new AppError("Error al comunicarse con el servicio de chat", 500, "N8N_ERROR");
  }
}