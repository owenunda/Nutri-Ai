-- Inicio de sesión con Google.
-- Los usuarios que se registran con Google no tienen contraseña, así que
-- password pasa a aceptar NULL. Cada cuenta externa vinculada es una fila en
-- user_auth_providers: provider_user_id es el "sub" de Google, que no cambia
-- aunque el usuario cambie de correo. Para añadir Apple basta con ampliar el CHECK.

ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

CREATE TABLE IF NOT EXISTS user_auth_providers (
    id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    provider         VARCHAR(20) NOT NULL CHECK (provider IN ('google')),
    provider_user_id VARCHAR(255) NOT NULL,
    email            VARCHAR(255),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_auth_provider_identity UNIQUE (provider, provider_user_id),
    CONSTRAINT uq_auth_provider_per_user UNIQUE (user_id, provider)
);
