import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// El job importa el repositorio (y con él la base): se reemplaza entero.
mock.module(src('modules/admin/admin.repository.js'), {
  exports: { expireGiftedPro: async () => [] },
});

const { runProExpiry } = await import(src('modules/admin/proExpiry.job.js'));

test('devuelve los usuarios que volvieron a FREE', async () => {
  assert.deepEqual(await runProExpiry(async () => [4, 9]), [4, 9]);
});

test('un fallo de la base no lanza', async () => {
  const original = console.error;
  console.error = () => {};
  try {
    const result = await runProExpiry(async () => {
      throw new Error('db caída');
    });
    assert.deepEqual(result, []);
  } finally {
    console.error = original;
  }
});
