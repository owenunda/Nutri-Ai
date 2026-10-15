import { test } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;
const { resolveLang, languageMiddleware } = await import(src('middleware/language.middleware.js'));

test('toma el idioma base de la etiqueta', () => {
  assert.equal(resolveLang('en-US'), 'en');
  assert.equal(resolveLang('es-MX'), 'es');
  assert.equal(resolveLang('EN'), 'en');
});

test('sin header o con un idioma no soportado responde en español', () => {
  assert.equal(resolveLang(undefined), 'es');
  assert.equal(resolveLang(''), 'es');
  assert.equal(resolveLang('fr'), 'es');
  assert.equal(resolveLang('*'), 'es');
});

test('elige el primer idioma soportado respetando q', () => {
  assert.equal(resolveLang('fr, en;q=0.8'), 'en');
  assert.equal(resolveLang('en;q=0.1, es;q=0.9'), 'es');
  assert.equal(resolveLang('es;q=0, en'), 'en');
});

test('el middleware deja el idioma en req.lang', () => {
  const req = { headers: { 'accept-language': 'en-GB,en;q=0.9' } };
  let called = false;
  languageMiddleware(req, {}, () => { called = true; });
  assert.equal(req.lang, 'en');
  assert.ok(called);
});
