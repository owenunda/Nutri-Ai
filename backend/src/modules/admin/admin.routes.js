import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getOverview, listUsers, getUserDetail, updateUserPlan } from './admin.controller.js';
import {
  validateOverviewQuery,
  validateListUsersQuery,
  validateUserIdParam,
  validatePlanBody,
} from './admin.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/admin/overview:
 *   get:
 *     tags: [Admin]
 *     summary: Resumen del panel admin (solo ADMIN)
 *     description: Usuarios, usuarios activos, consultas a la IA, errores, bots y series por día.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema: { type: integer, enum: [7, 14, 30, 90], default: 30 }
 *     responses:
 *       200:
 *         description: Resumen del periodo
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.get('/overview', authenticateToken(['ADMIN']), validateOverviewQuery, getOverview);

/**
 * @openapi
 * /api/v1/admin/users:
 *   get:
 *     tags: [Admin]
 *     summary: Listar usuarios con su uso de la app y de la IA (solo ADMIN)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *         description: Nombre, correo o id
 *       - in: query
 *         name: plan
 *         schema: { type: string, enum: [FREE, PRO] }
 *       - in: query
 *         name: sort
 *         schema: { type: string, enum: [recent, ai, activity, name], default: recent }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 25, maximum: 200 }
 *     responses:
 *       200:
 *         description: Lista paginada de usuarios
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.get('/users', authenticateToken(['ADMIN']), validateListUsersQuery, listUsers);

/**
 * @openapi
 * /api/v1/admin/users/{userId}:
 *   get:
 *     tags: [Admin]
 *     summary: Detalle de un usuario (solo ADMIN)
 *     description: Perfil, consultas a la IA, comidas, nevera, actividad por módulo y eventos recientes.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Detalle del usuario
 *       404:
 *         description: Usuario no encontrado
 */
router.get('/users/:userId', authenticateToken(['ADMIN']), validateUserIdParam, getUserDetail);

/**
 * @openapi
 * /api/v1/admin/users/{userId}/plan:
 *   patch:
 *     tags: [Admin]
 *     summary: Cambiar el plan de un usuario (solo ADMIN)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [plan]
 *             properties:
 *               plan: { type: string, enum: [FREE, PRO] }
 *     responses:
 *       200:
 *         description: Plan actualizado
 *       404:
 *         description: Usuario no encontrado
 */
router.patch('/users/:userId/plan',
  authenticateToken(['ADMIN']),
  validateUserIdParam,
  validatePlanBody,
  updateUserPlan
);

export default router;
