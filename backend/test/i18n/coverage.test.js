// backend/test/i18n/coverage.test.js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const srcDir = fileURLToPath(new URL('../../src/', import.meta.url));
const { CODE_MESSAGES, SOURCE_MESSAGES } = await import(new URL('../../src/i18n/messages.js', import.meta.url).href);

const jsFiles = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return name === 'database' ? [] : jsFiles(path);
    return path.endsWith('.js') ? [path] : [];
  });

const sources = jsFiles(srcDir).map((path) => ({ path, text: readFileSync(path, 'utf8') }));

test('cada código de error tiene texto en inglés', () => {
  const codes = new Set();
  for (const { text } of sources) {
    // new AppError(<mensaje>, <status>, 'CODE' ...) y errorResponse(res, <mensaje>, 'CODE', ...)
    for (const m of text.matchAll(/new AppError\(([\s\S]*?),\s*\d{3},\s*['"]([A-Z_]+)['"]/g)) codes.add(m[2]);
    for (const m of text.matchAll(/errorResponse\([^)]*?['"]([A-Z_]{4,})['"]/g)) codes.add(m[1]);
  }
  const missing = [...codes].filter((code) => !CODE_MESSAGES.en[code]);
  assert.deepEqual(missing, []);
});

test('cada detalle de validación tiene texto en los dos idiomas', () => {
  const messages = new Set();
  for (const { path, text } of sources) {
    if (!path.endsWith('.validation.js')) continue;
    for (const m of text.matchAll(/message:\s*'([^']+)'/g)) messages.add(m[1]);
  }
  const missing = [...messages].filter((msg) => !SOURCE_MESSAGES[msg]?.es || !SOURCE_MESSAGES[msg]?.en);
  assert.deepEqual(missing, []);
});
