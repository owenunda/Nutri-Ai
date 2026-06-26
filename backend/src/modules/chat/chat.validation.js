import { AppError } from '../../utils/AppError.js';

const VALID_ROLES = ['USER', 'ASSISTANT'];
const VALID_INTENTS = [
    'GENERATE_RECIPE_WITH_INPUT',
    'GENERATE_RECIPE_FROM_FRIDGE',
    'MODIFY_RECIPE',
    'ASK_RECIPE',
    'NEW_RECIPE'
];
const VALID_MEAL_TYPES = ['desayuno', 'almuerzo', 'cena'];

export const validateAddMessageRequest = (req, res, next) => {
    const { role, content } = req.body ?? {};
    const details = [];

    if (!role) {
        details.push({ field: 'role', message: 'El rol es requerido' });
    } else if (!VALID_ROLES.includes(role)) {
        details.push({ field: 'role', message: `El rol debe ser uno de: ${VALID_ROLES.join(', ')}` });
    }

    if (!content) {
        details.push({ field: 'content', message: 'El contenido es requerido' });
    } else if (typeof content !== 'string' || content.trim().length === 0) {
        details.push({ field: 'content', message: 'El contenido no puede estar vacío' });
    }

    if (details.length > 0) {
        return next(new AppError('Error de validación', 400, 'VALIDATION_ERROR', details));
    }

    req.messageData = {
        role,
        content: content.trim()
    };

    next();
};

export const validateUpdateConversationStateRequest = (req, res, next) => {
    const body = req.body ?? {};
    const { last_intent, metadata } = body;
    const details = [];

    if (last_intent !== undefined && last_intent !== null && !VALID_INTENTS.includes(last_intent)) {
        details.push({
            field: 'last_intent',
            message: `last_intent debe ser uno de: ${VALID_INTENTS.join(', ')} o null`
        });
    }

    if (metadata !== undefined && metadata !== null) {
        if (typeof metadata !== 'object' || Array.isArray(metadata)) {
            details.push({ field: 'metadata', message: 'metadata debe ser un objeto' });
        } else {
            const { meal_type, servings, version } = metadata;

            if (meal_type !== undefined && meal_type !== null && !VALID_MEAL_TYPES.includes(meal_type)) {
                details.push({
                    field: 'metadata.meal_type',
                    message: `meal_type debe ser uno de: ${VALID_MEAL_TYPES.join(', ')} o null`
                });
            }

            if (servings !== undefined && servings !== null) {
                const parsedServings = Number(servings);
                if (!Number.isInteger(parsedServings) || parsedServings <= 0) {
                    details.push({ field: 'metadata.servings', message: 'servings debe ser un entero positivo' });
                }
            }

            if (version !== undefined && version !== null) {
                const parsedVersion = Number(version);
                if (!Number.isInteger(parsedVersion) || parsedVersion < 1) {
                    details.push({ field: 'metadata.version', message: 'version debe ser un entero mayor o igual a 1' });
                }
            }
        }
    }

    if (details.length > 0) {
        return next(new AppError('Error de validación', 400, 'VALIDATION_ERROR', details));
    }

    const existingMetadata = metadata ?? {};
    req.conversationStateData = {
        recipe: body.recipe ?? null,
        media: body.media ?? null,
        last_intent: last_intent ?? null,
        metadata: {
            meal_type: existingMetadata.meal_type ?? null,
            servings: existingMetadata.servings ?? null,
            generated_at: existingMetadata.generated_at ?? null,
            last_modified_at: existingMetadata.last_modified_at ?? null,
            version: existingMetadata.version ?? 1
        }
    };

    next();
};
