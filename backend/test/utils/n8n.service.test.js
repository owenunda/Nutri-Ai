import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const posts = [];
mock.module('axios', {
  exports: {
    default: {
      post: async (url, payload) => {
        posts.push(payload);
        return { data: { ok: true } };
      },
    },
  },
});

const { config } = await import(src('config/env_config.js'));
config.n8n.url_dev = config.n8n.url_dev || 'http://n8n.test/webhook';
config.n8n.url_pro = config.n8n.url_pro || 'http://n8n.test/webhook';

const { sendChatN8n } = await import(src('utils/n8n.service.js'));

test('manda el idioma a n8n', async () => {
  await sendChatN8n('hola', 7, 'Ana', 'jwt', [], 'en');
  assert.equal(posts.at(-1).language, 'en');
});

test('sin idioma manda español', async () => {
  await sendChatN8n('hola', 7, 'Ana', 'jwt');
  assert.equal(posts.at(-1).language, 'es');
});
