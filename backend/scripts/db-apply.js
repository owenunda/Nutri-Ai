// Aplica scripts SQL de src/database/backups contra la base del .env.
//
//   npm run db:apply                                   → lista los update_*.sql
//   npm run db:apply -- update_12_10_2026_meals.sql    → muestra qué haría (no ejecuta)
//   npm run db:apply -- update_12_10_2026_meals.sql --yes  → lo ejecuta
//
// Sin --yes no toca la base: así se ve contra qué host y base va antes de
// correr algo en producción.
import { readFileSync, readdirSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve, basename, isAbsolute } from 'path';
import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const __dirname = dirname(fileURLToPath(import.meta.url));
const backupsDir = resolve(__dirname, '../src/database/backups');

const args = process.argv.slice(2);
const confirmed = args.includes('--yes');
const files = args.filter((a) => a !== '--yes');

// update_DD_MM_YYYY[_algo].sql → orden cronológico
const sortKey = (name) => {
  const m = name.match(/update_(\d{2})_(\d{2})_(\d{4})/);
  return m ? `${m[3]}${m[2]}${m[1]}${name}` : name;
};

if (files.length === 0) {
  const updates = readdirSync(backupsDir)
    .filter((f) => /^update_.*\.sql$/.test(f))
    .sort((a, b) => (sortKey(a) < sortKey(b) ? -1 : 1));
  console.log('Uso: npm run db:apply -- <archivo.sql> [...] [--yes]\n');
  console.log('Scripts disponibles (del más viejo al más nuevo):');
  updates.forEach((f) => console.log(`  ${f}`));
  process.exit(0);
}

const resolveFile = (name) => {
  const path = isAbsolute(name) ? name : resolve(backupsDir, basename(name));
  if (!existsSync(path)) {
    console.error(`No existe: ${path}`);
    process.exit(1);
  }
  return path;
};
const paths = files.map(resolveFile);

const required = ['HOST_DB', 'PORT_DB', 'USER_DB', 'PASS_DB', 'NAME_DB'];
const missing = required.filter((k) => !process.env[k]?.trim());
if (missing.length > 0) {
  console.error(`Faltan variables en backend/.env: ${missing.join(', ')}`);
  process.exit(1);
}

const target = `${process.env.HOST_DB.trim()}:${process.env.PORT_DB.trim()}/${process.env.NAME_DB.trim()}`;
console.log(`Base: ${target}`);
paths.forEach((p) => console.log(`  - ${basename(p)}`));

if (!confirmed) {
  console.log('\nNo se ejecutó nada. Agrega --yes para aplicarlos.');
  process.exit(0);
}

const client = new pg.Client({
  host: process.env.HOST_DB.trim(),
  port: Number(process.env.PORT_DB.trim()),
  user: process.env.USER_DB.trim(),
  password: process.env.PASS_DB.trim(),
  database: process.env.NAME_DB.trim(),
});

try {
  await client.connect();
  for (const path of paths) {
    const sql = readFileSync(path, 'utf8');
    // Los scripts que no traen su propia transacción se envuelven en una,
    // para que un error a mitad no deje la base a medias.
    const ownTransaction = /^\s*BEGIN\s*;/im.test(sql);
    console.log(`\nAplicando ${basename(path)}...`);
    if (ownTransaction) {
      await client.query(sql);
    } else {
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    }
    console.log(`OK ${basename(path)}`);
  }
} catch (error) {
  console.error(`\nFalló: ${error.message}`);
  console.error('Ese script no quedó aplicado; los anteriores de la lista sí.');
  process.exitCode = 1;
} finally {
  await client.end();
}
