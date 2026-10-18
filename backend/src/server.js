import 'dotenv/config';
import app from './app.js';
import { config } from './config/env_config.js';
import pool from './database/connection.js';
import { AppError } from './utils/AppError.js';
import { startProExpiryJob } from './modules/admin/proExpiry.job.js';
import { startGuestCleanupJob } from './modules/auth/guestCleanup.job.js';

const PORT = config.port;
const dbConfigured = config.db?.host && config.db?.user && config.db?.name;

if (dbConfigured) {
  pool.connect()
    .then((client) => {
      client.release();
      console.info('Base de datos conectada');
      startProExpiryJob();
      startGuestCleanupJob();
    })
    .catch(err => {
      throw new AppError('Error al conectar a la base de datos', 500, 'DATABASE_ERROR', err);
    });
} else if (config.node_env === 'development') {
  console.warn('No hay configuración de base de datos. Iniciando en modo desarrollo sin DB.');
} else {
  throw new AppError('Database configuration is required', 500, 'DATABASE_NOT_CONFIGURED');
}

app.listen(PORT, () => {
  console.log(`El servidor está corriendo en el puerto http://localhost:${PORT}`);
  console.log(`Checar el estado del servidor en: http://localhost:${PORT}/api/v1/health`);
});
