import { config } from '../../config/env_config.js';
import { AppError } from '../../utils/AppError.js';

const RESEND_URL = 'https://api.resend.com/emails';

const sendFailed = () =>
  new AppError('No se pudo enviar el correo. Inténtalo de nuevo.', 502, 'EMAIL_SEND_FAILED');

// Envía un correo con la API de Resend. El detalle de un fallo solo va al log:
// al cliente le llega un mensaje genérico.
export const sendEmail = async ({ to, subject, html, text }) => {
  const { resendApiKey, from } = config.email;

  if (!resendApiKey || !from) {
    throw new AppError('Email is not configured', 500, 'EMAIL_CONFIG_ERROR');
  }

  let response;
  try {
    response = await fetch(RESEND_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from, to: [to], subject, html, text }),
    });
  } catch (error) {
    console.error('[email] No se pudo contactar a Resend:', error.message);
    throw sendFailed();
  }

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    console.error(`[email] Resend respondió ${response.status}:`, detail);
    throw sendFailed();
  }
};
