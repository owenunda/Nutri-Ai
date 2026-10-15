import { test, mock } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

mock.module(src('modules/events/events.service.js'), {
  exports: { logEventService: async () => {} },
});

const { AppError } = await import(src('utils/AppError.js'));
const { errorHandler, notFoundHandler } = await import(src('middleware/error.middleware.js'));
const { config } = await import(src('config/env_config.js'));

const fakeRes = () => {
  const res = { statusCode: null, body: null };
  res.status = (code) => { res.statusCode = code; return res; };
  res.json = (body) => { res.body = body; return res; };
  return res;
};

test('responde en inglés cuando la petición es en inglés', () => {
  const res = fakeRes();
  errorHandler(new AppError('El código no es correcto.', 400, 'INVALID_CODE'), { lang: 'en' }, res, () => {});
  assert.equal(res.statusCode, 400);
  assert.equal(res.body.message, 'That code is not correct.');
  assert.equal(res.body.error.code, 'INVALID_CODE');
});

test('sin idioma responde en español', () => {
  const res = fakeRes();
  errorHandler(new AppError('El código no es correcto.', 400, 'INVALID_CODE'), {}, res, () => {});
  assert.equal(res.body.message, 'El código no es correcto.');
});

test('traduce los detalles de validación', () => {
  const res = fakeRes();
  const err = new AppError('Validation error', 400, 'VALIDATION_ERROR', [
    { field: 'email', message: 'Email is required' },
  ]);
  errorHandler(err, { lang: 'es' }, res, () => {});
  assert.equal(res.body.error.details[0].message, 'El correo electrónico es obligatorio.');
});

test('usa los params del error', () => {
  const res = fakeRes();
  const err = new AppError('Espera 30 segundos para pedir otro código.', 429, 'CODE_RECENTLY_SENT', [], { seconds: 30 });
  errorHandler(err, { lang: 'en' }, res, () => {});
  assert.equal(res.body.message, 'Wait 30 seconds before asking for another code.');
});

test('un error inesperado en producción responde un mensaje genérico en el idioma pedido', () => {
  const previousEnv = config.node_env;
  config.node_env = 'production';
  try {
    const en = fakeRes();
    errorHandler(new Error('boom interno'), { lang: 'en' }, en, () => {});
    assert.equal(en.statusCode, 500);
    assert.equal(en.body.message, 'Something went wrong. Please try again.');

    const es = fakeRes();
    errorHandler(new Error('boom interno'), { lang: 'es' }, es, () => {});
    assert.equal(es.body.message, 'Algo salió mal');
  } finally {
    config.node_env = previousEnv;
  }
});

test('la ruta inexistente sigue llegando al manejador', () => {
  let forwarded;
  notFoundHandler({ originalUrl: '/nada' }, {}, (err) => { forwarded = err; });
  assert.equal(forwarded.code, 'ROUTE_NOT_FOUND');
});
