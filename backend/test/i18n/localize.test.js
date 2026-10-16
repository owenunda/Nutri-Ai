import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { localizeError } = await import(src('i18n/localize.js'));

test('en español deja igual un mensaje que ya está en español', () => {
  const out = localizeError({ code: 'INVALID_CODE', message: 'El código no es correcto.' }, 'es');
  assert.equal(out.message, 'El código no es correcto.');
});

test('en español traduce un mensaje de origen en inglés', () => {
  const out = localizeError({ code: 'EMAIL_ALREADY_EXISTS', message: 'Email is already registered' }, 'es');
  assert.equal(out.message, 'Ese correo ya está registrado.');
});

test('en inglés traduce por código', () => {
  const out = localizeError({ code: 'INVALID_CODE', message: 'El código no es correcto.' }, 'en');
  assert.equal(out.message, 'That code is not correct.');
});

test('en inglés usa los params del error', () => {
  const out = localizeError(
    { code: 'CODE_RECENTLY_SENT', message: 'Espera 42 segundos para pedir otro código.', params: { seconds: 42 } },
    'en'
  );
  assert.equal(out.message, 'Wait 42 seconds before asking for another code.');
});

test('un código sin traducción devuelve el mensaje original', () => {
  const out = localizeError({ code: 'SOMETHING_NEW', message: 'Algo nuevo' }, 'en');
  assert.equal(out.message, 'Algo nuevo');
});

test('traduce los mensajes de los detalles y deja los demás campos', () => {
  const out = localizeError(
    {
      code: 'VALIDATION_ERROR',
      message: 'Validation error',
      details: [
        { field: 'email', message: 'Email is required' },
        { field: 'x', message: 'Texto sin traducción' },
        'texto suelto',
      ],
    },
    'es'
  );
  assert.equal(out.message, 'Revisa los campos marcados e inténtalo de nuevo.');
  assert.deepEqual(out.details, [
    { field: 'email', message: 'El correo electrónico es obligatorio.' },
    { field: 'x', message: 'Texto sin traducción' },
    'texto suelto',
  ]);
});

test('un código o mensaje con nombre de propiedad heredada no rompe nada', () => {
  const out = localizeError({ code: 'constructor', message: 'toString' }, 'en');
  assert.equal(out.message, 'toString');
  const otro = localizeError({ code: 'INVALID_CODE', message: 'hasOwnProperty' }, '__proto__');
  assert.equal(otro.message, 'hasOwnProperty');
});
