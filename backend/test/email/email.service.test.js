import { test, mock, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';

const src = (path) => new URL(`../../src/${path}`, import.meta.url).href;

const { config } = await import(src('config/env_config.js'));
const { sendEmail } = await import(src('modules/email/email.service.js'));
const { codeEmail } = await import(src('modules/email/email.templates.js'));

let calls;

beforeEach(() => {
  calls = [];
  config.email.resendApiKey = 're_test';
  config.email.from = 'NutriLife <no-reply@test.dev>';
  mock.method(console, 'error', () => {});
});

afterEach(() => {
  mock.restoreAll();
});

const fakeFetch = (response) =>
  mock.method(globalThis, 'fetch', async (url, options) => {
    calls.push({ url, options });
    if (response instanceof Error) throw response;
    return response;
  });

test('envía el correo a Resend con la API key y el remitente', async () => {
  fakeFetch(new Response('{"id":"1"}', { status: 200 }));

  await sendEmail({ to: 'ana@gmail.com', subject: 'Hola', html: '<p>Hola</p>', text: 'Hola' });

  assert.equal(calls[0].url, 'https://api.resend.com/emails');
  assert.equal(calls[0].options.headers.Authorization, 'Bearer re_test');
  assert.deepEqual(JSON.parse(calls[0].options.body), {
    from: 'NutriLife <no-reply@test.dev>',
    to: ['ana@gmail.com'],
    subject: 'Hola',
    html: '<p>Hola</p>',
    text: 'Hola',
  });
});

test('Resend responde error: 502 EMAIL_SEND_FAILED', async () => {
  fakeFetch(new Response('{"message":"invalid"}', { status: 422 }));

  await assert.rejects(sendEmail({ to: 'ana@gmail.com', subject: 's', html: 'h', text: 't' }), {
    status: 502,
    code: 'EMAIL_SEND_FAILED',
  });
});

test('sin red: 502 EMAIL_SEND_FAILED', async () => {
  fakeFetch(new Error('ECONNRESET'));

  await assert.rejects(sendEmail({ to: 'ana@gmail.com', subject: 's', html: 'h', text: 't' }), {
    status: 502,
    code: 'EMAIL_SEND_FAILED',
  });
});

test('sin configuración: 500 EMAIL_CONFIG_ERROR y no llama a Resend', async () => {
  fakeFetch(new Response('{}', { status: 200 }));
  config.email.resendApiKey = undefined;

  await assert.rejects(sendEmail({ to: 'ana@gmail.com', subject: 's', html: 'h', text: 't' }), {
    status: 500,
    code: 'EMAIL_CONFIG_ERROR',
  });
  assert.equal(calls.length, 0);
});

test('envía las imágenes inline cuando las hay', async () => {
  fakeFetch(new Response('{"id":"1"}', { status: 200 }));
  const attachments = [
    { filename: 'n.png', content: 'AAAA', content_type: 'image/png', content_id: 'nutria' },
  ];

  await sendEmail({ to: 'ana@gmail.com', subject: 's', html: 'h', text: 't', attachments });

  assert.deepEqual(JSON.parse(calls[0].options.body).attachments, attachments);
});

test('plantillas: el código aparece en el HTML y en el texto', () => {
  for (const purpose of ['verify_email', 'reset_password']) {
    const email = codeEmail({ purpose, code: '482913', name: 'Ana' });

    assert.ok(email.subject.length > 0);
    assert.match(email.html, /482913/);
    assert.match(email.text, /482913/);
    assert.match(email.text, /Ana/);
  }
});

test('plantillas: llevan la nutria como imagen inline, distinta para cada correo', () => {
  const verify = codeEmail({ purpose: 'verify_email', code: '482913', name: 'Ana' });
  const reset = codeEmail({ purpose: 'reset_password', code: '482913', name: 'Ana' });

  for (const email of [verify, reset]) {
    const [image] = email.attachments;
    assert.equal(image.content_id, 'nutria');
    assert.equal(image.content_type, 'image/png');
    assert.match(email.html, /src="cid:nutria"/);
    // PNG en base64 empieza por la firma "iVBORw0KGgo".
    assert.ok(image.content.startsWith('iVBORw0KGgo'));
  }
  assert.notEqual(verify.attachments[0].content, reset.attachments[0].content);
});

test('plantillas: en inglés cambian asunto, saludo y pie', () => {
  for (const purpose of ['verify_email', 'reset_password']) {
    const es = codeEmail({ purpose, code: '482913', name: 'Ana' });
    const en = codeEmail({ purpose, code: '482913', name: 'Ana', lang: 'en' });

    assert.notEqual(en.subject, es.subject);
    assert.match(en.text, /^Hi Ana,/);
    assert.match(en.text, /15 minutes/);
    assert.match(en.html, /482913/);
    assert.match(es.text, /^Hola Ana,/);
  }
});

test('plantillas: un idioma desconocido usa español', () => {
  const email = codeEmail({ purpose: 'verify_email', code: '482913', name: 'Ana', lang: 'fr' });
  assert.match(email.text, /^Hola Ana,/);
});
