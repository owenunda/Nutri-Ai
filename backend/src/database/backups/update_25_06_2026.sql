-- Módulo de sesiones conversacionales
-- Cada usuario puede tener solo UNA sesión activa (restricción via índice parcial único)

CREATE TABLE IF NOT EXISTS chat_sessions (
    session_id  SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(user_id),
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    conversation_state JSONB NOT NULL DEFAULT '{
        "recipe": null,
        "media": null,
        "last_intent": null,
        "metadata": {
            "meal_type": null,
            "servings": null,
            "generated_at": null,
            "last_modified_at": null,
            "version": 1
        }
    }',
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Garantiza que cada usuario tenga como máximo una sesión activa simultánea
CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_sessions_active_user
    ON chat_sessions (user_id)
    WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id
    ON chat_sessions (user_id);

-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_messages (
    message_id  SERIAL PRIMARY KEY,
    session_id  INTEGER NOT NULL REFERENCES chat_sessions(session_id),
    role        VARCHAR(20) NOT NULL CHECK (role IN ('USER', 'ASSISTANT')),
    content     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id
    ON chat_messages (session_id);
