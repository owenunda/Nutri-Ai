import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

// El job importa el repositorio (y con él la base): se reemplaza entero.
mock.module(src('modules/admin/admin.repository.js'), {
  exports: { expireGiftedPro: async () => [] },
});

// Y el service de suscripciones (RevenueCat y la base).
mock.module(src('modules/subscription/subscription.service.js'), {
  exports: { renewDueStoreSubscriptions: async () => ({ checked: 0, failed: 0, stopped: false }) },
});

const { runProExpiry } = await import(src('modules/admin/proExpiry.job.js'));

const noRenewals = async () => ({ checked: 0, failed: 0, stopped: false });

test('devuelve los usuarios que volvieron a FREE', async () => {
  assert.deepEqual(await runProExpiry(async () => [4, 9], noRenewals), [4, 9]);
});

test('un fallo de la base no lanza', async () => {
  const original = console.error;
  console.error = () => {};
  try {
    const result = await runProExpiry(async () => {
      throw new Error('db caída');
    }, noRenewals);
    assert.deepEqual(result, []);
  } finally {
    console.error = original;
  }
});

test('pregunta a RevenueCat por las renovaciones antes de vencer', async () => {
  const order = [];
  await runProExpiry(
    async () => {
      order.push('expire');
      return [];
    },
    async () => {
      order.push('renew');
      return { checked: 0, failed: 0, stopped: false };
    }
  );
  assert.deepEqual(order, ['renew', 'expire']);
});

test('si la revisión de renovaciones lanza, igual vence', async () => {
  const original = console.error;
  console.error = () => {};
  try {
    const result = await runProExpiry(
      async () => [4],
      async () => {
        throw new Error('inesperado');
      }
    );
    assert.deepEqual(result, [4]);
  } finally {
    console.error = original;
  }
});
