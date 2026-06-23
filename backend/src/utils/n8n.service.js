import { config } from '../config/env_config.js';
import axios from 'axios';
import { AppError } from './AppError.js'
import { errorResponse } from './response.js';

const URL_WEBHOOK = config.node_env === "development" ? config.n8n.url_dev : config.n8n.url_pro

export const sendChatN8n = async (message, userId, userName, token) => {
  console.log("Enviando a n8n:", { message, userId, userName, hasToken: !!token });
  try {
    const payload = {
      parameters: {
        userId,
        name: userName,
        message,
        token
      }
    }
    const response = await axios.post(URL_WEBHOOK, payload);

    return response.data;
  } catch (error) {
    console.error("Error al enviar mensaje a n8n:", error.response?.data || error.message);
    throw new AppError("Error al comunicarse con el servicio de chat", 500, "N8N_ERROR");
  }
}