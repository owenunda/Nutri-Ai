import dotenv from 'dotenv';
dotenv.config();


const env = process.env;

const trim = (value) =>
  typeof value === 'string' ? value.trim().replace(/^['"]|['"]$/g, '') : undefined;

const nodeEnv = trim(env.NODE_ENV) || 'development';
const jwtSecret = trim(env.JWT_SECRET) || (nodeEnv === 'development' ? 'dev_secret' : undefined);
const port = trim(env.PORT) || '3000';

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
  n8n: {
    url_dev: trim(env.N8N_URL_DEV),
    url_pro: trim(env.N8N_URL_PRO),
  },
};
