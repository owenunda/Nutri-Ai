-- =========================================================
-- TABLA: activity_events
-- Registro de eventos de actividad para auditoría y panel admin.
-- Captura auth, uso de IA/recetas, errores del sistema y acciones CRUD.
-- metadata (JSONB) permite adjuntar un payload flexible por evento.
-- =========================================================
CREATE TABLE activity_events (
    event_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type  VARCHAR(60) NOT NULL,        -- LOGIN, LOGIN_FAILED, LOGOUT, REGISTER,
                                             -- RECIPE_GENERATED, AI_CHAT, SYSTEM_ERROR,
                                             -- CRUD_CREATE, CRUD_UPDATE, CRUD_DELETE, HTTP_REQUEST, ...
    category    VARCHAR(30) NOT NULL,        -- AUTH | AI | ERROR | CRUD | SYSTEM
    user_id     INTEGER,                     -- nullable (eventos anónimos / login fallido)
    method      VARCHAR(10),                 -- GET/POST/... (logging automático)
    path        VARCHAR(255),
    status_code INTEGER,
    ip_address  VARCHAR(45),
    metadata    JSONB DEFAULT '{}'::jsonb,   -- payload flexible por evento
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_event FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX idx_events_type     ON activity_events(event_type);
CREATE INDEX idx_events_category ON activity_events(category);
CREATE INDEX idx_events_user     ON activity_events(user_id);
CREATE INDEX idx_events_created  ON activity_events(created_at DESC);
