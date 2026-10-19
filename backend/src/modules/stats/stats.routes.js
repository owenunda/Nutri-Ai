import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getCalorieStreak, getConsumptionValidation, getTodayCalories, getWeekStats } from './stats.controller.js';

const router = Router();

/**
 * @openapi
 * /api/v1/stats/consumption-validation:
 *   get:
 *     tags: [Stats]
 *     summary: Validar si el consumo calórico del usuario está dentro de su meta
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         required: false
 *         description: Día local del usuario (YYYY-MM-DD). Si se omite se usa el día UTC del servidor.
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Resultado de la validación de consumo
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         isWithinGoal:
 *                           type: boolean
 *                         consumed:
 *                           type: number
 *                         target:
 *                           type: number
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/consumption-validation',
  authenticateToken(['USER', 'ADMIN']),
  getConsumptionValidation
);

/**
 * @openapi
 * /api/v1/stats/today-calories:
 *   get:
 *     tags: [Stats]
 *     summary: Obtener calorías totales consumidas hoy
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         required: false
 *         description: Día local del usuario (YYYY-MM-DD). Si se omite se usa el día UTC del servidor.
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Calorías consumidas en el día actual
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         totalCalories:
 *                           type: number
 *                           example: 1450.5
 *                         date:
 *                           type: string
 *                           format: date
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.get('/today-calories',
  authenticateToken(['USER', 'ADMIN']),
  getTodayCalories
);

/**
 * @openapi
 * /api/v1/stats/week:
 *   get:
 *     tags: [Stats]
 *     summary: Resumen de calorías de los últimos 7 días
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: end
 *         required: false
 *         description: Último día del rango (YYYY-MM-DD), normalmente el día local del usuario. Si se omite se usa el día UTC del servidor.
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Calorías por día de los 7 días que terminan en `end`
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         start:
 *                           type: string
 *                           format: date
 *                         end:
 *                           type: string
 *                           format: date
 *                         dailyLimit:
 *                           type: number
 *                           nullable: true
 *                           description: Meta diaria en kcal, null si faltan edad, altura o peso
 *                         days:
 *                           type: array
 *                           description: 7 días en orden ascendente
 *                           items:
 *                             type: object
 *                             properties:
 *                               date:
 *                                 type: string
 *                                 format: date
 *                               totalConsumed:
 *                                 type: number
 *                         average:
 *                           type: number
 *                           description: Promedio diario de kcal de los 7 días
 *                         daysOnTarget:
 *                           type: integer
 *                           description: Días dentro del rango de la meta según el objetivo (mismo criterio que /stats/calorie-streak)
 *       400:
 *         description: Fecha inválida (INVALID_DATE)
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: Usuario no encontrado
 */
router.get('/week',
  authenticateToken(['USER', 'ADMIN']),
  getWeekStats
);

/**
 * @openapi
 * /api/v1/stats/calorie-streak:
 *   get:
 *     summary: Racha del objetivo calórico con toda la historia
 *     description: >
 *       Un día cuenta si lo comido cae dentro del rango de la meta según el
 *       objetivo (bajar 70-100 %, mantener 85-115 %, subir 100-130 %).
 *     tags: [Stats]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *         description: Hoy en la fecha local de la app (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: current, best, dailyLimit, min y max (todos null si faltan edad, altura o peso)
 *       400:
 *         description: Fecha inválida (INVALID_DATE)
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         description: Usuario no encontrado
 */
router.get('/calorie-streak',
  authenticateToken(['USER', 'ADMIN']),
  getCalorieStreak
);

export default router;
