-- Verificación del correo y códigos para restablecer la contraseña.
-- email_verified_at: NULL = el usuario no demostró que el correo es suyo.
-- Los usuarios que ya existen se dan por verificados (decisión del spec
-- 2026-10-15-email-verification-design.md): nadie queda bloqueado al
-- actualizar la app.
-- email_codes: un solo código vigente por usuario y propósito; pedir uno nuevo
-- reemplaza la fila. Se guarda el hash, nunca el código.

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
