import { createClient } from 'redis';
import { config } from './env_config.js';
import { AppError } from '../utils/AppError.js';

// Tope de la primera conexión: con Redis caído, node-redis reintenta para
// siempre y connect() nunca rechaza. Así se falla rápido y se deja pasar.
const CONNECT_TIMEOUT_MS = 2000;
const MAX_INITIAL_RETRIES = 2;
const HARD_TIMEOUT_MS = 5000;

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
    let ready = false;
    // Sin cola offline: con Redis caído los comandos fallan al instante y se
    // cumple el fail-open del rate limit y de la cuota, en vez de quedar colgados.
    const c = createClient({
      url: config.redis.url,
      disableOfflineQueue: true,
      socket: {
        connectTimeout: CONNECT_TIMEOUT_MS,
        // El tope aplica solo a la primera conexión; si Redis cae después de
        // haber estado listo, se reconecta con el backoff normal.
        reconnectStrategy: (retries) =>
          !ready && retries >= MAX_INITIAL_RETRIES
            ? new Error('Redis no responde')
            : Math.min(retries * 50, 500),
      },
    });
    c.on('error', (err) => {
      console.error('[redis] error de conexión:', err.message);
    });
    c.on('ready', () => {
      ready = true;
    });

    let timer;
    try {
      // Red de seguridad por si connect() queda colgado sin rechazar.
      await Promise.race([
        c.connect(),
        new Promise((_, reject) => {
          timer = setTimeout(
            () => reject(new Error('Redis connect timeout')),
            HARD_TIMEOUT_MS
          );
        }),
      ]);
    } catch (err) {
      // Que el siguiente llamado reintente en vez de reusar la promesa rechazada.
      connecting = null;
      client = null;
      Promise.resolve()
        .then(() => c.disconnect())
        .catch(() => {});
      throw err;
    } finally {
      clearTimeout(timer);
    }
    client = c;
    connecting = null;
    return c;
  })();

  return connecting;
};
