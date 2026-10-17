-- PRO regalado con duración desde el panel admin.
-- pro_until: hasta cuándo dura el PRO. NULL con plan PRO = sin vencimiento;
-- con plan FREE siempre NULL. Al vencer, el backend pasa al usuario a FREE
-- (spec 2026-10-17, regalar PRO con duración).
-- Columna nueva y nullable: no cambia a ningún usuario existente.

ALTER TABLE users ADD COLUMN IF NOT EXISTS pro_until TIMESTAMPTZ;
