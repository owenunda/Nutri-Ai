# Diseño: Verificar el correo y restablecer la contraseña

Parte 4 del trabajo de autenticación (sigue a `2026-10-14-google-auth-design.md` y
`2026-10-15-google-link-password-design.md`).

## Contexto

El registro con email no verifica el correo: cualquiera puede registrar un correo ajeno.
Tampoco existe "olvidé mi contraseña". No hay nada para enviar correos en el repo.

## Decisiones

| Tema | Decisión |
|---|---|
| Servicio de correo | Resend, dominio verificado `mailnutrifile.oween.software`. Remitente `NutriLife <no-reply@mailnutrifile.oween.software>`. |
| Forma de verificar | Código de 6 dígitos que se escribe en la app (sin deep links). |
| Sin verificar | No puede entrar hasta verificar. |
| Usuarios existentes | Se dan por verificados (`email_verified_at` = fecha de la migración). |
| Cuentas de Google | Verificadas al crearse; al vincular Google, la cuenta queda verificada. |
| Vincular Google | Sigue pidiendo la contraseña aunque el correo esté verificado: los usuarios dados por verificados nunca lo demostraron. |
| Dónde viven los códigos | Tabla `email_codes` en PostgreSQL (no Redis: si Redis cae, nadie podría verificar). |
| Restablecer contraseña | Mismo mecanismo de código. |

## Base de datos

`backend/src/database/backups/update_15_10_2026_email_verification.sql`:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP;
UPDATE users SET email_verified_at = CURRENT_TIMESTAMP WHERE email_verified_at IS NULL;

CREATE TABLE IF NOT EXISTS email_codes (
  id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  purpose     VARCHAR(20) NOT NULL CHECK (purpose IN ('verify_email', 'reset_password')),
  code_hash   VARCHAR(255) NOT NULL,
  expires_at  TIMESTAMP NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_email_code_per_purpose UNIQUE (user_id, purpose)
);
```

Un solo código vigente por usuario y propósito: pedir uno nuevo reemplaza la fila.
La migración es aditiva: el backend que hoy corre en producción no la usa y no se rompe.

## Backend

### Envío (`modules/email/email.service.js`)

`sendEmail({ to, subject, html, text })` hace `POST https://api.resend.com/emails` con
`fetch` (sin dependencias). Config: `RESEND_API_KEY`, `EMAIL_FROM`. Sin config →
`AppError` 500 `EMAIL_CONFIG_ERROR`. Si Resend responde error → 502 `EMAIL_SEND_FAILED`.
Plantillas en `modules/email/email.templates.js`: código de verificación y de restablecer.

### Códigos (`modules/auth/email-code.service.js`)

- `sendCode(user, purpose)`: si el último código de ese propósito se creó hace menos de
  60 s → 429 `CODE_RECENTLY_SENT` (con `retryAfter` en segundos). Si no, genera 6 dígitos
  con `crypto.randomInt`, guarda el hash bcrypt (reemplaza el anterior), vence en 15 min
  y envía el correo.
- `consumeCode(userId, purpose, code)`: sin código o vencido → 400 `CODE_EXPIRED`;
  5 intentos fallidos → 400 `CODE_EXPIRED`; incorrecto → suma un intento y 400
  `INVALID_CODE`; correcto → borra el código.

### Endpoints (todos con `strictAuthRateLimit`)

| Endpoint | Comportamiento |
|---|---|
| `POST /auth/register` | Crea la cuenta sin verificar y envía el código. Responde como antes más `verificationRequired: true`. |
| `POST /auth/login` | Contraseña correcta pero correo sin verificar → envía un código (si el cooldown lo permite) y 403 `EMAIL_NOT_VERIFIED`. |
| `POST /auth/verify-email` `{ email, code }` | Verifica, marca `email_verified_at` y responde la sesión `{ token, user, needsProfileSetup }`. Evento `EMAIL_VERIFIED`. |
| `POST /auth/verify-email/resend` `{ email }` | Si existe y no está verificado, envía. Siempre 200 (no revela correos), salvo 429 por cooldown. |
| `POST /auth/password/forgot` `{ email }` | Si existe, envía el código de restablecer. Siempre 200, salvo 429. |
| `POST /auth/password/reset` `{ email, code, password }` | Consume el código, guarda la contraseña (mín. 6), marca el correo verificado. Evento `PASSWORD_RESET`. 200. |

En verify/reset, un correo que no existe responde 400 `INVALID_CODE` (igual que un código
equivocado, para no revelar correos).

## App

- **Registro:** ya no inicia sesión sola; abre `VerifyEmailScreen(email)`.
- **`VerifyEmailScreen`:** "Te enviamos un código a {email}", campo de 6 dígitos,
  "Verificar" (guarda la sesión y abre la app), "Reenviar código" con cuenta regresiva de
  60 s, y volver.
- **Login:** ante `EMAIL_NOT_VERIFIED` abre `VerifyEmailScreen` (el código ya se envió).
  Enlace "¿Olvidaste tu contraseña?" → `ForgotPasswordScreen` (correo, "Enviar código")
  → `ResetPasswordScreen` (código, contraseña y confirmación) → vuelve al login con el
  correo escrito y un mensaje de éxito.
- **"Vincula tu cuenta":** enlace "¿Olvidaste tu contraseña?".

## Plan

1. Migración: escribirla y aplicarla con `npm run db:apply` (primero sin `--yes` para ver
   el destino).
2. Backend, TDD: `email.service` + plantillas (fetch simulado), `email-code.service`
   (repositorio simulado: crear, cooldown, vencido, intentos, incorrecto, correcto).
3. Backend, TDD: register/login con verificación, verify-email, resend, forgot, reset;
   Google crea y vincula verificado. Rutas, validaciones y OpenAPI. Commit.
4. App, TDD: repositorio (`verifyEmail`, `resendVerification`, `forgotPassword`,
   `resetPassword`, error `EMAIL_NOT_VERIFIED`) y `VerifyEmailScreen`; registro y login.
5. App: `ForgotPasswordScreen` y `ResetPasswordScreen` con widget tests; enlaces en login
   y en "Vincula tu cuenta".
6. `npm test`, `flutter analyze`, `flutter test`; commit y push.

## Fuera de alcance

- Cambiar el correo de una cuenta.
- Gestionar la verificación desde el admin-panel.
