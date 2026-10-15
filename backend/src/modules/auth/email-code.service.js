import { randomInt } from 'node:crypto';
import bcrypt from 'bcrypt';
import { AppError } from '../../utils/AppError.js';
import { sendEmail } from '../email/email.service.js';
import { codeEmail } from '../email/email.templates.js';
import {
  deleteCode,
  findCode,
  incrementCodeAttempts,
  upsertCode,
} from './email-code.repository.js';

export const CODE_PURPOSE = {
  VERIFY_EMAIL: 'verify_email',
  RESET_PASSWORD: 'reset_password',
};

const CODE_TTL_MINUTES = 15;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_ATTEMPTS = 5;
const SALT_ROUNDS = 10;

const codeExpired = () =>
  new AppError('El código venció. Pide uno nuevo.', 400, 'CODE_EXPIRED');

// Genera un código de 6 dígitos, guarda su hash (reemplazando el anterior) y
// lo envía por correo. Como mucho uno por minuto.
export const sendCode = async (user, purpose) => {
  const previous = await findCode(user.userId, purpose);
  if (previous) {
    const seconds = RESEND_COOLDOWN_SECONDS - previous.secondsSinceCreated;
    if (seconds > 0) {
      throw new AppError(
        `Espera ${seconds} segundos para pedir otro código.`,
        429,
        'CODE_RECENTLY_SENT',
        [],
        { seconds }
      );
    }
  }

  const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
  await upsertCode({
    userId: user.userId,
    purpose,
    codeHash: await bcrypt.hash(code, SALT_ROUNDS),
    ttlMinutes: CODE_TTL_MINUTES,
  });

  try {
    await sendEmail({ to: user.email, ...codeEmail({ purpose, code, name: user.name }) });
  } catch (error) {
    // Sin la fila, el usuario puede pedir otro código enseguida.
    await deleteCode(user.userId, purpose);
    throw error;
  }
};

// Comprueba el código y, si es correcto, lo borra: cada código sirve una vez.
export const consumeCode = async (userId, purpose, code) => {
  const stored = await findCode(userId, purpose);

  if (!stored || stored.expired || stored.attempts >= MAX_ATTEMPTS) {
    throw codeExpired();
  }

  if (!(await bcrypt.compare(code, stored.codeHash))) {
    await incrementCodeAttempts(userId, purpose);
    throw new AppError('El código no es correcto.', 400, 'INVALID_CODE');
  }

  await deleteCode(userId, purpose);
};
