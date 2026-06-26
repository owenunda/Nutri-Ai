import { AppError } from '../../utils/AppError.js';
import {
    findActiveSessionByUserIdRepository,
    createSessionRepository,
    updateConversationStateRepository,
    closeSessionRepository,
    addMessageRepository
} from './chat.repository.js';

export const getActiveSession = async (userId) => {
    try {
        return await findActiveSessionByUserIdRepository(userId);
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'CHAT_SERVICE_ERROR');
    }
};

export const createSession = async (userId) => {
    try {
        const existing = await findActiveSessionByUserIdRepository(userId);
        if (existing) {
            throw new AppError('El usuario ya tiene una sesión activa', 409, 'SESSION_ALREADY_EXISTS');
        }
        return await createSessionRepository(userId);
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'CHAT_SERVICE_ERROR');
    }
};

export const updateConversationState = async (userId, conversationState) => {
    try {
        const session = await findActiveSessionByUserIdRepository(userId);
        if (!session) {
            throw new AppError('No se encontró una sesión activa', 404, 'SESSION_NOT_FOUND');
        }
        const updated = await updateConversationStateRepository(session.sessionId, conversationState);
        if (!updated) {
            throw new AppError('No se pudo actualizar el estado de la sesión', 500, 'SESSION_UPDATE_ERROR');
        }
        return updated;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'CHAT_SERVICE_ERROR');
    }
};

export const addMessage = async (userId, role, content) => {
    try {
        const session = await findActiveSessionByUserIdRepository(userId);
        if (!session) {
            throw new AppError('No se encontró una sesión activa', 404, 'SESSION_NOT_FOUND');
        }
        return await addMessageRepository(session.sessionId, role, content);
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'CHAT_SERVICE_ERROR');
    }
};

export const closeSession = async (userId) => {
    try {
        const session = await findActiveSessionByUserIdRepository(userId);
        if (!session) {
            throw new AppError('No se encontró una sesión activa', 404, 'SESSION_NOT_FOUND');
        }
        const closed = await closeSessionRepository(session.sessionId);
        if (!closed) {
            throw new AppError('No se pudo cerrar la sesión', 500, 'SESSION_CLOSE_ERROR');
        }
        return closed;
    } catch (error) {
        if (error instanceof AppError) throw error;
        throw new AppError(error.message, 500, 'CHAT_SERVICE_ERROR');
    }
};
