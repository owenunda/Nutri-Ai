import 'dotenv/config';
import app from './app.js';
import { config } from './config/env_config.js';
import pool from './database/conection.js';

const PORT = config.port;

pool.connect()
  .then(() => console.info('Base de datos conectada'))
  .catch(err => {
    throw new AppError('Error al conectar a la base de datos', 500, 'DATABASE_ERROR', err)
  })

app.listen(PORT, () => {
  console.log(`El servidor está corriendo en el puerto http://localhost:${PORT}`);
  console.log(`Checar el estado del servidor en: http://localhost:${PORT}api/v1/health`);
});
