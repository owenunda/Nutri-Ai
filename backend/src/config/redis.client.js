import { createClient } from 'redis';
import { config } from './env_config.js';
import { AppError } from '../utils/AppError.js';

let client = null;
let connecting = null;

export const getRedisClient = async () => {
  if (client?.isOpen) return client;
  if (connecting) return connecting;

  if (!config.redis.url) {
    throw new AppError(
      'REDIS_URL no está configurada',
      500,
      'REDIS_CONFIG_ERROR'
    );
  }

  connecting = (async () => {
    const c = createClient({ url: config.redis.url });
    c.on('error', (err) => {
      console.error('[redis] error de conexión:', err.message);
    });
    await c.connect();
    client = c;
    connecting = null;
    return c;
  })();

  return connecting;
};