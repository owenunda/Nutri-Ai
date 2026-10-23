import dotenv from 'dotenv';
dotenv.config();


const env = process.env;

const trim = (value) =>
  typeof value === 'string' ? value.trim().replace(/^['"]|['"]$/g, '') : undefined;

const nodeEnv = trim(env.NODE_ENV) || 'development';
const jwtSecret = trim(env.JWT_SECRET) || (nodeEnv === 'development' ? 'dev_secret' : undefined);
const port = trim(env.PORT) || '3000';

const googleClientIds = (trim(env.GOOGLE_CLIENT_IDS) || '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);

export const config = {
  node_env: nodeEnv,
  port: Number(port),
  db: {
    host: trim(env.HOST_DB),
    user: trim(env.USER_DB),
    password: trim(env.PASS_DB),
    name: trim(env.NAME_DB),
    port: trim(env.PORT_DB),
  },
  jwt: {
    secret: jwtSecret,
  },
  google: {
    clientIds: googleClientIds,
  },
  email: {
    resendApiKey: trim(env.RESEND_API_KEY),
    from: trim(env.EMAIL_FROM),
  },
  n8n: {
    url_dev: trim(env.N8N_URL_DEV),
    url_pro: trim(env.N8N_URL_PRO),
    webhookSecret: trim(env.N8N_WEBHOOK_SECRET),
  },
  redis: {
    url: trim(env.REDIS_URL),
  },
  rateLimit: {
    chatPerMinute: Number(trim(env.RATE_LIMIT_CHAT_PER_MINUTE)) || 10,
    aiWebhookPerMinute: Number(trim(env.RATE_LIMIT_AI_WEBHOOK_PER_MINUTE)) || 60,
    authStrictPerMinute: Number(trim(env.RATE_LIMIT_AUTH_PER_MINUTE)) || 5,
    subscriptionSyncPerMinute: Number(trim(env.RATE_LIMIT_SUBSCRIPTION_SYNC_PER_MINUTE)) || 10,
    guestPerHour: Number(trim(env.RATE_LIMIT_GUEST_PER_HOUR)) || 5,
  },
  chatQuota: {
    freePerDay: Number(trim(env.CHAT_DAILY_LIMIT_FREE)) || 3,
    proPerDay: Number(trim(env.CHAT_DAILY_LIMIT_PRO)) || 50,
  },
  revenuecat: {
    secretKey: trim(env.REVENUECAT_SECRET_KEY),
    webhookAuth: trim(env.REVENUECAT_WEBHOOK_AUTH),
    // Solo mientras se prueba con la Test Store o con testers de las tiendas.
    allowSandbox: trim(env.REVENUECAT_ALLOW_SANDBOX) === 'true',
  },
  // Modo invitado de la beta. Apagado, POST /auth/guest responde 404.
  guestMode: {
    enabled: trim(env.GUEST_MODE_ENABLED) === 'true',
    // Tope de invitados vigentes a la vez: cada uno trae su cuota FREE de Chef IA.
    maxActive: Number(trim(env.GUEST_MAX_ACTIVE)) || 100,
  },
};
