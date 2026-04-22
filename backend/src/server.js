import 'dotenv/config';
import app from './app.js';
import { config } from './config/env_config.js';

const PORT = config.port;

app.listen(PORT, () => {
  console.log(`El servidor está corriendo en el puerto http://localhost:${PORT}`);
  console.log(`Checar el estado del servidor en: http://localhost:${PORT}/health`);
});
