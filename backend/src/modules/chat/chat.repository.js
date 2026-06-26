import pool from '../../database/connection.js';

const DEFAULT_CONVERSATION_STATE = {
    recipe: null,
    media: null,
    last_intent: null,
    metadata: {
        meal_type: null,
        servings: null,
        generated_at: null,
        last_modified_at: null,
        version: 1
    }
};

const SESSION_SELECT_FIELDS = `
    session_id          AS "sessionId",
    user_id             AS "userId",
    active,
    conversation_state  AS "conversationState",
    created_at          AS "createdAt",
    updated_at          AS "updatedAt"
`;

export const findActiveSessionByUserIdRepository = async (userId) => {
    const query = `
        SELECT ${SESSION_SELECT_FIELDS}
        FROM chat_sessions
        WHERE user_id = $1 AND active = TRUE
        LIMIT 1
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows[0] ?? null;
};

export const findSessionByIdRepository = async (sessionId) => {
    const query = `
        SELECT ${SESSION_SELECT_FIELDS}
        FROM chat_sessions
        WHERE session_id = $1
        LIMIT 1
    `;
    const { rows } = await pool.query(query, [sessionId]);
    return rows[0] ?? null;
};

export const createSessionRepository = async (userId) => {
    const query = `
        INSERT INTO chat_sessions (user_id, active, conversation_state)
        VALUES ($1, TRUE, $2::jsonb)
        RETURNING ${SESSION_SELECT_FIELDS}
    `;
    const { rows } = await pool.query(query, [userId, JSON.stringify(DEFAULT_CONVERSATION_STATE)]);
    return rows[0];
};

export const updateConversationStateRepository = async (sessionId, conversationState) => {
    const query = `
        UPDATE chat_sessions
        SET conversation_state = $1::jsonb,
            updated_at = NOW()
        WHERE session_id = $2 AND active = TRUE
        RETURNING ${SESSION_SELECT_FIELDS}
    `;
    const { rows } = await pool.query(query, [JSON.stringify(conversationState), sessionId]);
    return rows[0] ?? null;
};

export const closeSessionRepository = async (sessionId) => {
    const query = `
        UPDATE chat_sessions
        SET active = FALSE,
            updated_at = NOW()
        WHERE session_id = $1 AND active = TRUE
        RETURNING ${SESSION_SELECT_FIELDS}
    `;
    const { rows } = await pool.query(query, [sessionId]);
    return rows[0] ?? null;
};

export const addMessageRepository = async (sessionId, role, content) => {
    const query = `
        INSERT INTO chat_messages (session_id, role, content)
        VALUES ($1, $2, $3)
        RETURNING
            message_id  AS "messageId",
            session_id  AS "sessionId",
            role,
            content,
            created_at  AS "createdAt"
    `;
    const { rows } = await pool.query(query, [sessionId, role, content]);
    return rows[0];
};

export const findMessagesBySessionIdRepository = async (sessionId) => {
    const query = `
        SELECT
            message_id  AS "messageId",
            session_id  AS "sessionId",
            role,
            content,
            created_at  AS "createdAt"
        FROM chat_messages
        WHERE session_id = $1
        ORDER BY created_at ASC
    `;
    const { rows } = await pool.query(query, [sessionId]);
    return rows;
};
