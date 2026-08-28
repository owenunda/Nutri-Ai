import { spawn } from 'child_process';
import { existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import dotenv from 'dotenv';

dotenv.config();

const __dirname = dirname(fileURLToPath(import.meta.url));

const redisUrl = process.env.REDIS_URL;
if (!redisUrl) {
  console.error('REDIS_URL no está definida en .env');
  process.exit(1);
}

const localCli = process.platform === 'win32'
  ? resolve(__dirname, '../.tools/redis-cli.exe')
  : resolve(__dirname, '../.tools/redis-cli');

const redisBin = existsSync(localCli) ? localCli : 'redis-cli';

const command = process.argv[2];
const args = process.argv.slice(3);

const commands = {
  monitor: ['MONITOR'],
  ping: ['PING'],
  keys: ['--scan', '--pattern', 'rl:*'],
  flush: null,
  info: ['INFO', 'keyspace'],
};

if (!commands[command] && command !== 'flush') {
  console.error('Uso: node scripts/redis-cli.js <monitor|ping|keys|flush|info> [...args]');
  process.exit(1);
}

let redisArgs;
if (command === 'flush') {
  redisArgs = ['EVAL', `for _,k in ipairs(redis.call('keys', 'rl:*')) do redis.call('del', k) end return 'OK' end`, '0'];
} else {
  redisArgs = [...commands[command], ...args];
}

const child = spawn(redisBin, ['-u', redisUrl, ...redisArgs], {
  stdio: 'inherit',
});

child.on('exit', (code) => process.exit(code ?? 0));
child.on('error', (err) => {
  console.error('Error al ejecutar redis-cli:', err.message);
  process.exit(1);
});