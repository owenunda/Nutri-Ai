-- Racha de agua guardada en la base (spec 2026-10-17-agua-en-backend-design.md).
-- Una fila por usuario y día con vasos tomados (1 a 4). Un día sin vasos no
-- tiene fila. day es la fecha local del usuario, la que manda la app.

CREATE TABLE IF NOT EXISTS water_intake (
    user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    day         DATE NOT NULL,
    glasses     SMALLINT NOT NULL CHECK (glasses BETWEEN 1 AND 4),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, day)
);
