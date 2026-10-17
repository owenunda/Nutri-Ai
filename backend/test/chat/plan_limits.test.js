import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { CHAT_DAILY_LIMITS, chatDailyLimitFor } = await import(src('config/plan_limits.js'));

test('por defecto FREE tiene 3 mensajes y PRO 50', () => {
  assert.equal(CHAT_DAILY_LIMITS.FREE, 3);
  assert.equal(CHAT_DAILY_LIMITS.PRO, 50);
});

test('cada plan conocido usa su límite', () => {
  assert.equal(chatDailyLimitFor('FREE'), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor('PRO'), CHAT_DAILY_LIMITS.PRO);
});

test('un plan desconocido o vacío usa el límite FREE', () => {
  assert.equal(chatDailyLimitFor('GOLD'), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor(null), CHAT_DAILY_LIMITS.FREE);
  assert.equal(chatDailyLimitFor('constructor'), CHAT_DAILY_LIMITS.FREE);
});
