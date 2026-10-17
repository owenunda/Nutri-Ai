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
    // Sin cola offline: con Redis caído los comandos fallan al instante y se
    // cumple el fail-open del rate limit y de la cuota, en vez de quedar colgados.
    const c = createClient({ url: config.redis.url, disableOfflineQueue: true });
    c.on('error', (err) => {
      console.error('[redis] error de conexión:', err.message);
    });
    try {
      await c.connect();
    } catch (err) {
      // Que el siguiente llamado reintente en vez de reusar la promesa rechazada.
      connecting = null;
      client = null;
      throw err;
    }
    client = c;
    connecting = null;
    return c;
  })();

  return connecting;
};