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
 */
