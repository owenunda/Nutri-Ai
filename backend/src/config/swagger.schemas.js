/**
 * @openapi
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         userId:
 *           type: integer
 *         name:
 *           type: string
 *         email:
 *           type: string
 *           format: email
 *         role:
 *           type: string
 *           example: USER
 *         plan:
 *           type: string
 *           example: FREE
 *         goal:
 *           type: string
 *           description: User's nutritional goal
 *
 *     Food:
 *       type: object
 *       properties:
 *         foodId:
 *           type: integer
 *         name:
 *           type: string
 *         caloriesPerUnit:
 *           type: number
 *         baseUnit:
 *           type: string
 *           example: g
 *         isGlobal:
 *           type: boolean
 *         isActive:
 *           type: boolean
 *         createdByUserId:
 *           type: integer
 *           nullable: true
 *
 *     FridgeItem:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         foodId:
 *           type: integer
 *         quantity:
 *           type: number
 *         unit:
 *           type: string
 *         food:
 *           type: object
 *
 *     PhysicalRecord:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         height:
 *           type: number
 *           description: Height in cm
 *         weight:
 *           type: number
 *           description: Weight in kg
 *         createdAt:
 *           type: string
 *           format: date-time
 *
 *     Recipe:
 *       type: object
 *       properties:
 *         recipeId:
 *           type: integer
 *         name:
 *           type: string
 *         description:
 *           type: string
 *         status:
 *           type: string
 *           example: pending
 *         createdAt:
 *           type: string
 *           format: date-time
 *
 *     Ingredient:
 *       type: object
 *       required:
 *         - name
 *       properties:
 *         name:
 *           type: string
 *           example: tomate
 *         quantity:
 *           type: number
 *           nullable: true
 *           example: 3
 *
 *     MatchedFood:
 *       type: object
 *       properties:
 *         foodId:
 *           type: integer
 *         name:
 *           type: string
 *         caloriesPerUnit:
 *           type: number
 *         baseUnit:
 *           type: string
 *         quantity:
 *           type: number
 *
 *     ChatRequest:
 *       type: object
 *       required:
 *         - message
 *       properties:
 *         message:
 *           type: string
 *           example: Quiero un plan de comida para hoy
 *
 *     ApiResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *         data:
 *           type: object
 *           nullable: true
 *         message:
 *           type: string
 *
 *     ConversationStateMetadata:
 *       type: object
 *       properties:
 *         meal_type:
 *           type: string
 *           nullable: true
 *           enum: [desayuno, almuerzo, cena, null]
 *           example: almuerzo
 *         servings:
 *           type: integer
 *           nullable: true
 *           example: 4
 *         generated_at:
 *           type: string
 *           format: date-time
 *           nullable: true
 *         last_modified_at:
 *           type: string
 *           format: date-time
 *           nullable: true
 *         version:
 *           type: integer
 *           minimum: 1
 *           example: 1
 *
 *     ConversationState:
 *       type: object
 *       properties:
 *         recipe:
 *           type: object
 *           nullable: true
 *           description: Receta generada por el Chef Agent
 *         media:
 *           type: object
 *           nullable: true
 *           description: Respuesta del Media Agent
 *         last_intent:
 *           type: string
 *           nullable: true
 *           enum:
 *             - GENERATE_RECIPE_WITH_INPUT
 *             - GENERATE_RECIPE_FROM_FRIDGE
 *             - MODIFY_RECIPE
 *             - ASK_RECIPE
 *             - NEW_RECIPE
 *           example: GENERATE_RECIPE_WITH_INPUT
 *         metadata:
 *           $ref: '#/components/schemas/ConversationStateMetadata'
 *       example:
 *         recipe: null
 *         media: null
 *         last_intent: null
 *         metadata:
 *           meal_type: null
 *           servings: null
 *           generated_at: null
 *           last_modified_at: null
 *           version: 1
 *
 *     ChatSession:
 *       type: object
 *       properties:
 *         sessionId:
 *           type: integer
 *           example: 1
 *         userId:
 *           type: integer
 *           example: 42
 *         active:
 *           type: boolean
 *           example: true
 *         conversationState:
 *           $ref: '#/components/schemas/ConversationState'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *
 *     ChatMessage:
 *       type: object
 *       properties:
 *         messageId:
 *           type: integer
 *           example: 7
 *         sessionId:
 *           type: integer
 *           example: 1
 *         role:
 *           type: string
 *           enum: [USER, ASSISTANT]
 *           example: USER
 *         content:
 *           type: string
 *           example: Hazla para 4 personas
 *         createdAt:
 *           type: string
 *           format: date-time
 *
 *   responses:
 *     UnauthorizedError:
 *       description: Token no proporcionado o inválido
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ApiResponse'
 *           example:
 *             success: false
 *             data: null
 *             message: Unauthorized
 *
 *     NotFoundError:
 *       description: Recurso no encontrado
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ApiResponse'
 *           example:
 *             success: false
 *             data: null
 *             message: Not found
 *
 *     BadRequestError:
 *       description: Datos de la solicitud inválidos
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ApiResponse'
 *
 *     ForbiddenError:
 *       description: El rol del usuario no tiene permisos para este recurso
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ApiResponse'
 *           example:
 *             success: false
 *             data: null
 *             message: Unauthorized role
 */
