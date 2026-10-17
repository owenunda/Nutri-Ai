import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { validateDayBody, validateImportBody, isValidDay } = await import(
  src('modules/hydration/hydration.validation.js')
);

const today = new Date().toISOString().slice(0, 10);
const shift = (days) => new Date(Date.now() + days * 86_400_000).toISOString().slice(0, 10);

const run = (validator, body) => {
  const req = { body };
  let nextArg = 'not-called';
  validator(req, {}, (arg) => {
    nextArg = arg;
  });
  return { req, error: nextArg };
};

test('isValidDay acepta solo fechas reales YYYY-MM-DD', () => {
  assert.equal(isValidDay('2026-10-17'), true);
  assert.equal(isValidDay('2026-02-30'), false);
  assert.equal(isValidDay('17/10/2026'), false);
  assert.equal(isValidDay(20261017), false);
});

test('date de hoy, ayer o mañana pasa', () => {
  for (const date of [today, shift(-1), shift(1)]) {
    const { req, error } = run(validateDayBody, { date });
    assert.equal(error, undefined);
    assert.equal(req.hydrationDate, date);
  }
});

for (const body of [{}, { date: 'hoy' }, { date: shift(-3) }, { date: shift(3) }, undefined]) {
  test(`date inválida ${JSON.stringify(body)} responde 400`, () => {
    const { error } = run(validateDayBody, body);
    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'date');
  });
}

test('import válido pasa y recorta 5 a 4', () => {
  const { req, error } = run(validateImportBody, { history: { [shift(-1)]: 5, [today]: 2 } });
  assert.equal(error, undefined);
  assert.deepEqual(req.hydrationHistory, { [shift(-1)]: 4, [today]: 2 });
});

for (const history of [
  undefined,
  [],
  'x',
  { 'no-es-fecha': 2 },
  { [today]: 0 },
  { [today]: 6 },
  { [today]: 2.5 },
  { [shift(5)]: 2 },
]) {
  test(`import inválido ${JSON.stringify(history)} responde 400`, () => {
    const { error } = run(validateImportBody, { history });
    assert.equal(error.status, 400);
    assert.equal(error.details[0].field, 'history');
  });
}

test('import con más de 1000 días responde 400', () => {
  const history = {};
  for (let i = 0; i < 1001; i++) history[shift(-i - 1)] = 1;
  const { error } = run(validateImportBody, { history });
  assert.equal(error.status, 400);
});
