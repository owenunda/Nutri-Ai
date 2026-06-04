/**
 * @openapi
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         name:
 *           type: string
 *         email:
 *           type: string
 *           format: email
 *         goal:
 *           type: string
 *           description: User's nutritional goal
 *
 *     Food:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         name:
 *           type: string
 *         calories_per_unit:
 *           type: number
 *           description: Calories per base unit
 *         proteins:
 *           type: number
 *         carbohydrates:
 *           type: number
 *         fats:
 *           type: number
 *         base_unit:
 *           type: string
 *           description: Base unit of measurement (e.g., "g", "ml")
 *
 *     FridgeItem:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         foodId:
 *           type: integer
 *           description: Reference to food id
 *         quantity:
 *           type: number
 *         unit:
 *           type: string
 *           description: Unit of measurement
 *         food:
 *           type: object
 *           description: Associated food object
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
 *   responses:
 *     UnauthorizedError:
 *       description: Token not provided or invalid
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               success:
 *                 type: boolean
 *                 example: false
 *               message:
 *                 type: string
 *                 example: "Unauthorized"
 */
