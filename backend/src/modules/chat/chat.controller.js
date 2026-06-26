import { successResponse } from '../../utils/response.js';
import {
    getActiveSession,
    getSessionsByUser,
    createSession,
    updateConversationState,
    addMessage,
    closeSession
} from './chat.service.js';

export const getActiveSessionController = async (req, res, next) => {
    try {
        const session = await getActiveSession(req.user.userId);
        if (!session) {
            return successResponse(res, { hasActiveSession: false }, 'No hay sesión activa', 200);
        }
        return successResponse(res, { hasActiveSession: true, session }, 'Sesión activa obtenida correctamente', 200);
    } catch (error) {
        next(error);
    }
};

export const getSessionsController = async (req, res, next) => {
    try {
        const sessions = await getSessionsByUser(req.user.userId);
        return successResponse(res, sessions, 'Sesiones obtenidas correctamente', 200);
    } catch (error) {
        next(error);
    }
};

export const createSessionController = async (req, res, next) => {
    try {
        const session = await createSession(req.user.userId);
        return successResponse(res, session, 'Sesión creada correctamente', 201);
    } catch (error) {
        next(error);
    }
};

export const updateConversationStateController = async (req, res, next) => {
    try {
        const session = await updateConversationState(req.user.userId, req.conversationStateData);
        return successResponse(res, session, 'Estado de la sesión actualizado correctamente', 200);
    } catch (error) {
        next(error);
    }
};

export const addMessageController = async (req, res, next) => {
    try {
        const message = await addMessage(req.user.userId, req.messageData.role, req.messageData.content);
        return successResponse(res, message, 'Mensaje agregado correctamente', 201);
    } catch (error) {
        next(error);
    }
};

export const closeSessionController = async (req, res, next) => {
    try {
        const session = await closeSession(req.user.userId);
        return successResponse(res, session, 'Sesión cerrada correctamente', 200);
    } catch (error) {
        next(error);
    }
};
