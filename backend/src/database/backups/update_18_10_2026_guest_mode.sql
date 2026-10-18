-- Modo invitado para la beta (spec 2026-10-18-modo-invitado-design.md).
-- guest_expires_at: hasta cuándo dura la cuenta de invitado. NULL = cuenta
-- normal. Al vencer, el job guestCleanup la borra con todos sus datos.
-- Columna nueva y nullable: no cambia a ningún usuario existente.

ALTER TABLE users ADD COLUMN IF NOT EXISTS guest_expires_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_guest_expires_at
    ON users (guest_expires_at)
    WHERE guest_expires_at IS NOT NULL;
