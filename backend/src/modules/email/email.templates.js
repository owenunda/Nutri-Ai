// Correos con un código de 6 dígitos: verificar el correo o restablecer la
// contraseña. HTML con estilos en línea (los clientes de correo ignoran <style>)
// y una versión en texto plano.

const COPY = {
  verify_email: {
    subject: 'Tu código para verificar tu correo en NutriLife',
    intro: 'Usa este código para verificar tu correo en NutriLife:',
  },
  reset_password: {
    subject: 'Tu código para restablecer tu contraseña de NutriLife',
    intro: 'Usa este código para crear una contraseña nueva en NutriLife:',
  },
};

const escapeHtml = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

export const codeEmail = ({ purpose, code, name }) => {
  const { subject, intro } = COPY[purpose];
  const greeting = `Hola ${name},`;
  const footer =
    'El código vence en 15 minutos. Si no fuiste tú, puedes ignorar este correo.';

  const html = `
<div style="font-family:Arial,Helvetica,sans-serif;background:#f8fafc;padding:32px 16px;">
  <div style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:24px;padding:32px;">
    <p style="margin:0 0 4px;color:#0a6b3f;font-weight:800;letter-spacing:1px;font-size:12px;">NUTRILIFE</p>
    <p style="margin:16px 0 8px;color:#2c2f31;font-size:16px;">${escapeHtml(greeting)}</p>
    <p style="margin:0 0 24px;color:#595c5e;font-size:15px;line-height:1.5;">${intro}</p>
    <p style="margin:0 0 24px;text-align:center;font-size:36px;font-weight:800;letter-spacing:10px;color:#2c2f31;">${code}</p>
    <p style="margin:0;color:#6b7280;font-size:13px;line-height:1.5;">${footer}</p>
  </div>
</div>`.trim();

  const text = `${greeting}\n\n${intro}\n\n${code}\n\n${footer}`;

  return { subject, html, text };
};
