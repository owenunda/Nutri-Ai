/**
 * @openapi
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         nombre:
 *           type: string
 *         email:
 *           type: string
 *           format: email
 *     
 *     Food:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         nombre:
 *           type: string
 *         calorias:
 *           type: number
 *         proteinas:
 *           type: number
 *         carbohidratos:
 *           type: number
 *         grasas:
 *           type: number
 *
 *   responses:
 *     UnauthorizedError:
 *       description: Token no proporcionado o inválido
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
 *                 example: "No autorizado"
 */
