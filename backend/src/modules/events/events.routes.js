import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { listEvents, getStats, runRetention } from './events.controller.js';
import { validateListEventsQuery, validateRetention } from './events.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/admin/events:
 *   get:
 *     tags: [Admin Events]
 *     summary: Listar eventos de actividad (solo ADMIN)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema: { type: string }
 *         description: Filtra por event_type (ej. LOGIN, RECIPE_GENERATED)
 *       - in: query
 *         name: category
 *         schema: { type: string, enum: [AUTH, AI, ERROR, CRUD, SYSTEM] }
 *       - in: query
 *         name: userId
 *         schema: { type: integer }
 *       - in: query
 *         name: from
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: to
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 50, maximum: 500 }
 *     responses:
 *       200:
 *         description: Lista paginada de eventos
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
 *                         total: { type: integer }
 *                         items:
 *                           type: array
 *                           items: { type: object }
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.get('/',
  authenticateToken(['ADMIN']),
  validateListEventsQuery,
  listEvents
);

/**
 * @openapi
 * /api/v1/admin/events/stats:
 *   get:
 *     tags: [Admin Events]
 *     summary: Estadísticas agregadas de eventos (solo ADMIN)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: from
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: to
 *         schema: { type: string, format: date-time }
 *     responses:
 *       200:
 *         description: Métricas agregadas (por tipo, categoría, día y top usuarios)
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
 *                         total: { type: integer }
 *                         byType: { type: array, items: { type: object } }
 *                         byCategory: { type: array, items: { type: object } }
 *                         byDay: { type: array, items: { type: object } }
 *                         topUsers: { type: array, items: { type: object } }
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.get('/stats',
  authenticateToken(['ADMIN']),
  validateListEventsQuery,
  getStats
);

/**
 * @openapi
 * /api/v1/admin/events:
 *   delete:
 *     tags: [Admin Events]
 *     summary: Ejecutar política de retención (solo ADMIN)
 *     description: Elimina eventos más antiguos que N días. Opcionalmente filtra por type.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [days]
 *             properties:
 *               days: { type: integer, example: 30 }
 *               type: { type: string, example: HTTP_REQUEST }
 *     responses:
 *       200:
 *         description: Resultado de la retención (número de eventos eliminados)
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
 *                         deleted: { type: integer }
 *                         days: { type: integer }
 *                         type: { type: string, nullable: true }
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.delete('/',
  authenticateToken(['ADMIN']),
  validateRetention,
  runRetention
);

export default router;
