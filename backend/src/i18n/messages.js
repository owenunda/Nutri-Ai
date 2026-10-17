// backend/src/i18n/messages.js

// Traducciones de los errores que ve el usuario.
//
// SOURCE_MESSAGES: por texto original exacto. Cubre los mensajes que nacieron
// en inglés (necesitan español; antes los traducía la app) y los detalles de
// validación. Lo más específico: se mira primero.
//
// CODE_MESSAGES: por código de AppError. `en` cubre todos los códigos; `es`
// solo los que tienen un mensaje en inglés armado con datos variables.
// Un valor puede ser una función que recibe los `params` del error.

export const SOURCE_MESSAGES = {
  // Mensajes de AppError escritos en inglés
  'Validation error': {
    es: 'Revisa los campos marcados e inténtalo de nuevo.',
    en: 'Check the highlighted fields and try again.',
  },
  'Email is already registered': {
    es: 'Ese correo ya está registrado.',
    en: 'That email is already registered.',
  },
  'Invalid credentials': {
    es: 'Correo o contraseña inválidos.',
    en: 'Invalid email or password.',
  },
  'Contraseña incorrecta': {
    es: 'La contraseña no es correcta.',
    en: 'That password is not correct.',
  },
  'User not found': {
    es: 'No se encontró el usuario autenticado.',
    en: 'We could not find your account.',
  },
  'Default role or plan is not configured': {
    es: 'Falta configurar el rol o plan por defecto.',
  },
  'JWT secret is not configured': {
    es: 'Falta configurar el secreto JWT en el backend.',
  },
  'Invalid token': { es: 'Tu sesión no es válida. Vuelve a iniciar sesión.' },
  'No token provided': { es: 'Inicia sesión para continuar.' },
  'Unauthorized role': { es: 'No tienes permiso para hacer esto.' },
  'At least one field must be provided for update': { es: 'Envía al menos un dato para actualizar.' },
  'Base unit cannot be empty': { es: 'La unidad base no puede estar vacía.' },
  'Calories must be a number greater than 0': { es: 'Las calorías deben ser un número mayor a 0.' },
  'Cannot deactivate global food items': { es: 'No puedes desactivar alimentos del catálogo general.' },
  'Food item is already deactivated': { es: 'Ese alimento ya está desactivado.' },
  'Food item not found or inactive': { es: 'No se encontró el alimento o está inactivo.' },
  'Food item not found': { es: 'No se encontró el alimento.' },
  'Food item with this name already exists': { es: 'Ya existe un alimento con ese nombre.' },
  'Fridge item not found or does not belong to user': { es: 'Ese alimento no está en tu nevera.' },
  'Fridge not found for this user': { es: 'No se encontró tu nevera.' },
  'Item ID must be a positive integer': { es: 'El ID del ítem debe ser un entero positivo.' },
  'Missing required fields: foodId, quantity, or unit': { es: 'Faltan datos: alimento, cantidad o unidad.' },
  'Missing required fields: name, calories_per_unit, or base_unit': {
    es: 'Faltan datos: nombre, calorías por unidad o unidad base.',
  },
  'Name cannot be empty': { es: 'El nombre no puede estar vacío.' },
  'Recipe already exists for this user': { es: 'Ya tienes esa receta guardada.' },
  'Recipe not found or does not belong to user': { es: 'No se encontró la receta.' },
  'Request body is required and must be JSON': { es: 'La petición debe traer datos en JSON.' },
  'Unauthorized: You can only deactivate your own food items': {
    es: 'Solo puedes desactivar los alimentos que creaste.',
  },
  'Unauthorized: You can only edit your own food items': { es: 'Solo puedes editar los alimentos que creaste.' },
  'User already has a fridge': { es: 'Ya tienes una nevera.' },
  'foodId must be a positive integer': { es: 'El ID del alimento debe ser un entero positivo.' },
  'quantity is required': { es: 'La cantidad es obligatoria.' },
  'quantity must be a number greater than 0': { es: 'La cantidad debe ser un número mayor a 0.' },
  'quantity must be a number greater than or equal to 0': { es: 'La cantidad debe ser un número mayor o igual a 0.' },
  'unit cannot be empty': { es: 'La unidad no puede estar vacía.' },
  'Bad request': { es: 'Falta el mensaje.', en: 'The message is missing.' },
  // Respuesta genérica de errorHandler para errores no previstos en producción
  'Algo salió mal': { en: 'Something went wrong. Please try again.' },

  // Detalles de validación ({ field, message }) de src/modules/*/*.validation.js
  'Age must be an integer between 16 and 120': {
    es: 'La edad debe estar entre 16 y 120 años.',
    en: 'Age must be between 16 and 120.',
  },
  'At least one field must be provided: age, weight, height or goal': {
    es: 'Debes enviar al menos un dato para actualizar.',
    en: 'Send at least one field to update.',
  },
  'Code must be 6 digits': { es: 'El código debe tener 6 dígitos.', en: 'The code must have 6 digits.' },
  'El contenido es requerido': { es: 'El contenido es requerido.', en: 'Content is required.' },
  'El contenido no puede estar vacío': { es: 'El contenido no puede estar vacío.', en: 'Content cannot be empty.' },
  'El rol es requerido': { es: 'El rol es requerido.', en: 'Role is required.' },
  'El sessionId debe ser un entero positivo': {
    es: 'El sessionId debe ser un entero positivo.',
    en: 'sessionId must be a positive integer.',
  },
  'Email format is invalid': {
    es: 'El formato del correo electrónico no es válido.',
    en: 'The email format is not valid.',
  },
  'Email is required': { es: 'El correo electrónico es obligatorio.', en: 'Email is required.' },
  'Goal must be a non-empty string': { es: 'Selecciona una meta para continuar.', en: 'Choose a goal to continue.' },
  'Goal must contain a single value': { es: 'Selecciona una sola meta.', en: 'Choose only one goal.' },
  'Google idToken is required': { es: 'Falta el token de Google.', en: 'The Google token is missing.' },
  'Height is required': { es: 'La altura es obligatoria.', en: 'Height is required.' },
  'Height must be a number greater than 0': { es: 'La altura debe ser un número válido.', en: 'Height must be a valid number.' },
  'Name is required': { es: 'El nombre es obligatorio.', en: 'Name is required.' },
  'Password is required': { es: 'La contraseña es obligatoria.', en: 'Password is required.' },
  'Password must be at least 6 characters': {
    es: 'La contraseña debe tener al menos 6 caracteres.',
    en: 'Password must be at least 6 characters.',
  },
  'Send either password or googleIdToken': {
    es: 'Envía la contraseña o el token de Google.',
    en: 'Send either the password or the Google token.',
  },
  'Weight is required': { es: 'El peso es obligatorio.', en: 'Weight is required.' },
  'Weight must be a number greater than 0': { es: 'El peso debe ser un número válido.', en: 'Weight must be a valid number.' },
  'days must be a positive integer': { es: 'days debe ser un entero positivo.', en: 'days must be a positive integer.' },
  'from must be a valid ISO date': { es: 'from debe ser una fecha ISO válida.', en: 'from must be a valid ISO date.' },
  'limit must be a positive integer': { es: 'limit debe ser un entero positivo.', en: 'limit must be a positive integer.' },
  'limit must be an integer between 1 and 200': {
    es: 'limit debe ser un entero entre 1 y 200.',
    en: 'limit must be an integer between 1 and 200.',
  },
  'limit must be an integer between 1 and 500': {
    es: 'limit debe ser un entero entre 1 y 500.',
    en: 'limit must be an integer between 1 and 500.',
  },
  'metadata debe ser un objeto': { es: 'metadata debe ser un objeto.', en: 'metadata must be an object.' },
  'page and limit must be sent together': {
    es: 'page y limit deben enviarse juntos.',
    en: 'page and limit must be sent together.',
  },
  'page must be a positive integer': { es: 'page debe ser un entero positivo.', en: 'page must be a positive integer.' },
  'servings debe ser un entero positivo': {
    es: 'servings debe ser un entero positivo.',
    en: 'servings must be a positive integer.',
  },
  'to must be a valid ISO date': { es: 'to debe ser una fecha ISO válida.', en: 'to must be a valid ISO date.' },
  'type must be a non-empty string': { es: 'type no puede estar vacío.', en: 'type must be a non-empty string.' },
  'userId must be a positive integer': { es: 'userId debe ser un entero positivo.', en: 'userId must be a positive integer.' },
  'version debe ser un entero mayor o igual a 1': {
    es: 'version debe ser un entero mayor o igual a 1.',
    en: 'version must be an integer greater than or equal to 1.',
  },
};

const SOMETHING_WENT_WRONG = 'Something went wrong. Please try again.';

export const CODE_MESSAGES = {
  es: {
    DUPLICATE_INGREDIENT: 'Ese alimento ya está en la receta.',
  },
  en: {
    // Auth y correo
    UNAUTHORIZED: 'Please sign in again.',
    FORBIDDEN: 'You do not have permission to do this.',
    INVALID_PASSWORD: 'That password is not correct.',
    USER_NOT_FOUND: 'There is no account with that email.',
    EMAIL_ALREADY_EXISTS: 'That email is already registered.',
    EMAIL_NOT_VERIFIED: 'Verify your email: we sent you a code.',
    USE_GOOGLE_SIGN_IN: 'This account uses Google. Tap “Continue with Google”.',
    GOOGLE_ACCOUNT_MISMATCH: 'That Google account does not match this profile.',
    GOOGLE_ACCOUNT_CONFLICT: 'This email is already linked to another Google account.',
    GOOGLE_LINK_REQUIRES_PASSWORD:
      'You already have an account with this email. Enter your password to link it with Google.',
    GOOGLE_EMAIL_NOT_VERIFIED: 'Your Google email is not verified.',
    INVALID_GOOGLE_TOKEN: 'We could not verify your Google account.',
    PASSWORD_ALREADY_SET: 'Your account already has a password.',
    CODE_EXPIRED: 'The code expired. Ask for a new one.',
    INVALID_CODE: 'That code is not correct.',
    CODE_RECENTLY_SENT: ({ seconds } = {}) =>
      seconds ? `Wait ${seconds} seconds before asking for another code.` : 'Wait a moment before asking for another code.',
    EMAIL_SEND_FAILED: 'We could not send the email. Please try again.',
    RATE_LIMIT_EXCEEDED: 'Too many requests. Try again in a few seconds.',

    // Validación y peticiones
    VALIDATION_ERROR: 'Some fields are not valid. Check them and try again.',
    BAD_REQUEST: 'The request is not valid.',
    ROUTE_NOT_FOUND: 'Route not found.',
    NOT_FOUND: 'Not found.',
    INVALID_ACTION: 'Invalid action. Use: accept, reject, execute.',
    ACTION_REQUIRED: 'The action is required (accept, reject, execute).',
    INVALID_DATE: 'The date must use the YYYY-MM-DD format.',
    INVALID_MEAL_TYPE: 'That meal type is not valid.',
    MISSING_PHYSICAL_DATA: 'Age, height or weight is missing to calculate your goal.',

    // Alimentos, nevera, comidas y recetas
    FOOD_NOT_FOUND: 'Some foods were not found.',
    DUPLICATE_FOOD: 'A food with that name already exists.',
    FRIDGE_NOT_FOUND: 'We could not find your fridge.',
    FRIDGE_ALREADY_EXISTS: 'You already have a fridge.',
    FRIDGE_ITEM_NOT_FOUND: 'That food is not in your fridge.',
    FOOD_ID_REQUIRED: 'Every ingredient needs a food_id.',
    ID_REQUIRED: 'Every item needs a food_id or a recipe_id.',
    ITEMS_REQUIRED: 'A list of items is required.',
    INGREDIENTS_REQUIRED: 'A list of ingredients is required.',
    RECIPES_REQUIRED: 'A list of recipes is required.',
    INVALID_QUANTITY: 'The quantity must be greater than 0.',
    UNIT_REQUIRED: 'The unit is required.',
    INVALID_INGREDIENT: 'Every ingredient needs a food_id and a quantity.',
    INCOMPLETE_RECIPE_DATA: 'The recipe is incomplete (name and ingredients are required).',
    DUPLICATE_INGREDIENT: 'That food is already in the recipe.',
    RECIPE_NOT_FOUND: 'Recipe not found.',
    RECIPE_NAME_REQUIRED: 'The recipe name is required.',
    RECIPE_ALREADY_EXISTS: 'You already saved that recipe.',
    RECIPE_LOG_NOT_FOUND: 'Recipe not found.',
    MEAL_RECORD_NOT_FOUND: 'Meal record not found.',
    MEAL_ITEM_NOT_FOUND: 'Item not found.',
    STATUS_ID_REQUIRED: 'The status ID is required.',
    INVALID_STATUS_ID: 'That status ID is not valid.',

    // Chat
    SESSION_ALREADY_EXISTS: 'You already have an active conversation.',
    SESSION_NOT_FOUND: 'Conversation not found.',
    SESSION_ACTIVATE_ERROR: 'We could not open the conversation.',
    SESSION_UPDATE_ERROR: 'We could not update the conversation.',
    SESSION_CLOSE_ERROR: 'We could not close the conversation.',
    N8N_ERROR: 'The Chef is taking a short break. Try again in a little while.',
    CHAT_DAILY_LIMIT: ({ limit } = {}) =>
      limit
        ? `You've used your ${limit} Chef AI message${limit === 1 ? '' : 's'} for today.`
        : "You've used your Chef AI messages for today.",
    CHAT_FAIR_USE_LIMIT: "You've reached today's fair-use limit. Come back tomorrow.",

    // Admin
    CANNOT_DEMOTE_SELF: 'You cannot remove your own admin role.',
    CANNOT_DELETE_SELF: 'You cannot delete your own account from the panel.',

    // Errores internos: nunca exponen detalles en inglés
    INTERNAL_ERROR: SOMETHING_WENT_WRONG,
    DATABASE_ERROR: SOMETHING_WENT_WRONG,
    DATABASE_NOT_CONFIGURED: SOMETHING_WENT_WRONG,
    AUTH_DEFAULTS_NOT_FOUND: SOMETHING_WENT_WRONG,
    AUTH_CONFIG_ERROR: SOMETHING_WENT_WRONG,
    EMAIL_CONFIG_ERROR: SOMETHING_WENT_WRONG,
    REDIS_CONFIG_ERROR: SOMETHING_WENT_WRONG,
    N8N_CONFIG_ERROR: SOMETHING_WENT_WRONG,
    ADMIN_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    AI_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    AUTH_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    CHAT_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    EVENTS_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    FOOD_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    FRIDGE_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    MEAL_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    RECIPE_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    STATS_SERVICE_ERROR: SOMETHING_WENT_WRONG,
    USER_SERVICE_ERROR: SOMETHING_WENT_WRONG,
  },
};
