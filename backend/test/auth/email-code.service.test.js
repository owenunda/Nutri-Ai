import { test, mock, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import bcrypt from 'bcrypt';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const REPO_EXPORTS = ['deleteCode', 'findCode', 'incrementCodeAttempts', 'upsertCode'];

const repo = {};
const sentEmails = [];
let sendImpl;

mock.module(src('modules/auth/email-code.repository.js'), {
  exports: Object.fromEntries(
    REPO_EXPORTS.map((name) => [name, (...args) => repo[name](...args)])
  ),
});
mock.module(src('modules/email/email.service.js'), {
  exports: { sendEmail: (...args) => sendImpl(...args) },
});

const { AppError } = await import(src('utils/AppError.js'));
const { consumeCode, sendCode } = await import(src('modules/auth/email-code.service.js'));

const ana = { userId: 7, name: 'Ana', email: 'ana@gmail.com' };
const MINUTE = 60 * 1000;

let stored;
let deleted;
let attemptsAdded;

beforeEach(() => {
  sentEmails.length = 0;
  sendImpl = async (email) => {
    sentEmails.push(email);
  };
  stored = null;
  deleted = [];
  attemptsAdded = 0;
  repo.findCode = async () => stored;
  repo.upsertCode = async (row) => {
    stored = { ...row, attempts: 0, createdAt: new Date() };
  };
  repo.deleteCode = async (userId, purpose) => {
    deleted.push({ userId, purpose });
  };
  repo.incrementCodeAttempts = async () => {
    attemptsAdded += 1;
  };
});

const codeIn = (email) => email.text.match(/\b\d{6}\b/)[0];

test('enviar: guarda el hash del código y lo manda por correo', async () => {
  await sendCode(ana, 'verify_email');

  const code = codeIn(sentEmails[0]);
  assert.equal(sentEmails[0].to, 'ana@gmail.com');
  assert.equal(stored.userId, 7);
  assert.equal(stored.purpose, 'verify_email');
  assert.notEqual(stored.codeHash, code);
  assert.equal(await bcrypt.compare(code, stored.codeHash), true);
  const minutesLeft = (stored.expiresAt - Date.now()) / MINUTE;
  assert.ok(minutesLeft > 14 && minutesLeft <= 15);
});

test('enviar: antes de 60 segundos responde 429 y no envía', async () => {
  stored = { createdAt: new Date(Date.now() - 20 * 1000) };

  await assert.rejects(sendCode(ana, 'verify_email'), {
    status: 429,
    code: 'CODE_RECENTLY_SENT',
  });
  assert.equal(sentEmails.length, 0);
});

test('enviar: después de 60 segundos reemplaza el código', async () => {
  stored = { createdAt: new Date(Date.now() - 61 * 1000), codeHash: 'viejo' };

  await sendCode(ana, 'reset_password');

  assert.equal(sentEmails.length, 1);
  assert.notEqual(stored.codeHash, 'viejo');
});

test('enviar: si el correo falla borra el código para poder reintentar', async () => {
  sendImpl = async () => {
    throw new AppError('No se pudo enviar el correo.', 502, 'EMAIL_SEND_FAILED');
  };

  await assert.rejects(sendCode(ana, 'verify_email'), { code: 'EMAIL_SEND_FAILED' });
  // Sin la fila, el cooldown de 60 s no bloquea el reintento.
  assert.deepEqual(deleted, [{ userId: 7, purpose: 'verify_email' }]);
});

const storeCode = async (code, overrides = {}) => {
  stored = {
    codeHash: await bcrypt.hash(code, 4),
    expiresAt: new Date(Date.now() + 10 * MINUTE),
    attempts: 0,
    createdAt: new Date(),
    ...overrides,
  };
};

test('consumir: el código correcto se borra', async () => {
  await storeCode('482913');

  await consumeCode(7, 'verify_email', '482913');

  assert.deepEqual(deleted, [{ userId: 7, purpose: 'verify_email' }]);
});

test('consumir: código incorrecto suma un intento y responde 400 INVALID_CODE', async () => {
  await storeCode('482913');

  await assert.rejects(consumeCode(7, 'verify_email', '000000'), {
    status: 400,
    code: 'INVALID_CODE',
  });
  assert.equal(attemptsAdded, 1);
  assert.deepEqual(deleted, []);
});

test('consumir: sin código responde 400 CODE_EXPIRED', async () => {
  await assert.rejects(consumeCode(7, 'verify_email', '482913'), {
    status: 400,
    code: 'CODE_EXPIRED',
  });
});

test('consumir: código vencido responde 400 CODE_EXPIRED aunque sea correcto', async () => {
  await storeCode('482913', { expiresAt: new Date(Date.now() - 1000) });

  await assert.rejects(consumeCode(7, 'verify_email', '482913'), {
    status: 400,
    code: 'CODE_EXPIRED',
  });
});

test('consumir: con 5 intentos fallidos el código deja de servir', async () => {
  await storeCode('482913', { attempts: 5 });

  await assert.rejects(consumeCode(7, 'verify_email', '482913'), {
    status: 400,
    code: 'CODE_EXPIRED',
  });
});
