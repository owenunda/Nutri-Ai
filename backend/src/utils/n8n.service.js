import { config } from '../config/env_config.js';
import axios from 'axios';
import { AppError } from './AppError.js'
import { errorResponse } from './response.js';

const URL_WEBHOOK = config.node_env === "development" ? config.n8n.url_dev : config.n8n.url_pro

export const sendChatN8n = async (message, userId, userName) => {
  console.log(message, userId, userName);
  try {
    const payload = {
      parameters: {
        userId,
        name: userName,
        message
      }
    }
    const response = await axios.post(URL_WEBHOOK, payload);
    
    if(!response.ok){
      errorResponse(res, "Error al enviar el mensaje", "N8N_ERROR");
    }

    return response.data;
  } catch (error) {
    console.error("Error al enviar mensaje a n8n:", error);
    throw error;
    }
}