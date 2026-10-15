import { readFileSync } from 'node:fs';

// Correos con un código de 6 dígitos: verificar el correo o restablecer la
// contraseña. HTML con estilos en línea (los clientes de correo ignoran <style>)
// y una versión en texto plano. La nutria va como imagen inline (CID): Gmail
// no muestra imágenes data: y así no depende de una URL pública.

const NUTRIA_CID = 'nutria';

const loadImage = (file) =>
  readFileSync(new URL(`./assets/${file}`, import.meta.url)).toString('base64');

const COPY = {
  verify_email: {
    subject: 'Tu código para verificar tu correo en NutriLife',
    intro: 'Usa este código para verificar tu correo en NutriLife:',
    image: { file: 'nutria-saludando.png', content: loadImage('nutria-saludando.png') },
  },
  reset_password: {
    subject: 'Tu código para restablecer tu contraseña de NutriLife',
    intro: 'Usa este código para crear una contraseña nueva en NutriLife:',
    image: { file: 'nutria-pensando.png', content: loadImage('nutria-pensando.png') },
  },
};

const escapeHtml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

export const codeEmail = ({ purpose, code, name }) => {
  const { subject, intro, image } = COPY[purpose];
  const greeting = `Hola ${name},`;
  const footer =
    'El código vence en 15 minutos. Si no fuiste tú, puedes ignorar este correo.';

  const html = `
<div style="font-family:Arial,Helvetica,sans-serif;background:#f8fafc;padding:32px 16px;">
  <div style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:24px;padding:32px;text-align:center;">
    <img src="cid:${NUTRIA_CID}" width="96" height="96" alt="Nutria de NutriLife" style="display:block;margin:0 auto 12px;width:96px;height:96px;image-rendering:pixelated;" />
    <p style="margin:0 0 4px;color:#0a6b3f;font-weight:800;letter-spacing:1px;font-size:12px;">NUTRILIFE</p>
    <p style="margin:16px 0 8px;color:#2c2f31;font-size:16px;">${escapeHtml(greeting)}</p>
    <p style="margin:0 0 24px;color:#595c5e;font-size:15px;line-height:1.5;">${intro}</p>
    <div style="margin:0 auto 24px;display:inline-block;background:#ddf3e8;border-radius:16px;padding:14px 24px;">
      <span style="font-size:34px;font-weight:800;letter-spacing:10px;color:#0a6b3f;">${code}</span>
    </div>
    <p style="margin:0;color:#6b7280;font-size:13px;line-height:1.5;">${footer}</p>
  </div>
</div>`.trim();

  const text = `${greeting}\n\n${intro}\n\n${code}\n\n${footer}`;

  const attachments = [
    {
      filename: image.file,
      content: image.content,
      content_type: 'image/png',
      content_id: NUTRIA_CID,
    },
  ];

  return { subject, html, text, attachments };
};
