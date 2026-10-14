// Pone una contraseña nueva a un usuario que ya existe, por ejemplo un admin
// que la perdió al vincular Google.
//
//   npm run user:set-password -- correo@ejemplo.com
//
// La contraseña se pide por teclado dos veces y no se muestra en pantalla.
import bcrypt from 'bcrypt';
import pool from '../src/database/connection.js';
import { config } from '../src/config/env_config.js';

const SALT_ROUNDS = 10;
const MIN_LENGTH = 6;

const email = process.argv[2]?.trim().toLowerCase();

if (!email) {
  console.log('Uso: npm run user:set-password -- correo@ejemplo.com');
  process.exit(1);
}

// Lee una línea sin mostrar lo que se escribe.
const askHidden = (question) =>
  new Promise((resolve) => {
    const { stdin, stdout } = process;
    stdout.write(question);
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding('utf8');

    let value = '';
    const onData = (chunk) => {
      for (const char of chunk) {
        if (char === '\r' || char === '\n' || char === '\u0004') {
          stdin.setRawMode(false);
          stdin.pause();
          stdin.off('data', onData);
          stdout.write('\n');
          resolve(value);
          return;
        }
        if (char === '\u0003') {
          stdout.write('\nCancelado.\n');
          process.exit(1);
        }
        if (char === '\u007f' || char === '\b') {
          value = value.slice(0, -1);
        } else {
          value += char;
        }
      }
    };
    stdin.on('data', onData);
  });

try {
  const { rows } = await pool.query(
    `SELECT u.user_id AS "userId", u.name, r.name AS role
     FROM users u
     INNER JOIN roles r ON r.role_id = u.role_id
     WHERE LOWER(u.email) = $1
     LIMIT 1`,
    [email]
  );
  const user = rows[0];

  if (!user) {
    console.log(`No existe ningún usuario con el correo ${email}.`);
    process.exit(1);
  }

  console.log(`Base: ${config.db.name} en ${config.db.host}`);
  console.log(`Usuario: #${user.userId} ${user.name} (${user.role})`);

  const password = await askHidden('Contraseña nueva: ');
  if (password.length < MIN_LENGTH) {
    console.log(`La contraseña debe tener al menos ${MIN_LENGTH} caracteres.`);
    process.exit(1);
  }

  const confirmation = await askHidden('Repite la contraseña: ');
  if (confirmation !== password) {
    console.log('Las contraseñas no coinciden. No se cambió nada.');
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  await pool.query(
    'UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2',
    [passwordHash, user.userId]
  );

  console.log('Contraseña actualizada.');
} finally {
  await pool.end();
}
