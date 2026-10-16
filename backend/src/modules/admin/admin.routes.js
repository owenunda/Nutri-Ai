import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
  getOverview,
  listUsers,
  getUserDetail,
  updateUserPlan,
  updateUserPassword,
  updateUserRole,
  deleteUser,
} from './admin.controller.js';
import {
  validateOverviewQuery,
  validateListUsersQuery,
  validateUserIdParam,
  validatePlanBody,
  validatePasswordBody,
  validateRoleBody,
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

/**
 * @openapi
 * /api/v1/admin/users/{userId}/password:
 *   patch:
 *     tags: [Admin]
 *     summary: Poner una contraseña nueva a un usuario (solo ADMIN)
 *     description: Si el usuario solo entraba con Google, pasa a poder entrar también con contraseña.
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
 *             required: [password]
 *             properties:
 *               password: { type: string, minLength: 6 }
 *     responses:
 *       200:
 *         description: Contraseña actualizada
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       404:
 *         description: Usuario no encontrado
 */
router.patch('/users/:userId/password',
  authenticateToken(['ADMIN']),
  validateUserIdParam,
  validatePasswordBody,
  updateUserPassword
);

/**
 * @openapi
 * /api/v1/admin/users/{userId}/role:
 *   patch:
 *     tags: [Admin]
 *     summary: Dar o quitar el rol de administrador (solo ADMIN)
 *     description: El cambio se aplica en el próximo inicio de sesión del usuario. Un admin no puede quitarse el rol a sí mismo.
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
 *             required: [role]
 *             properties:
 *               role: { type: string, enum: [ADMIN, USER] }
 *     responses:
 *       200:
 *         description: Rol actualizado
 *       404:
 *         description: Usuario no encontrado
 *       409:
 *         description: Un admin no puede quitarse el rol a sí mismo (code CANNOT_DEMOTE_SELF)
 */
router.patch('/users/:userId/role',
  authenticateToken(['ADMIN']),
  validateUserIdParam,
  validateRoleBody,
  updateUserRole
);

/**
 * @openapi
 * /api/v1/admin/users/{userId}:
 *   delete:
 *     tags: [Admin]
 *     summary: Eliminar la cuenta de un usuario y todos sus datos (solo ADMIN)
 *     description: Borra de forma permanente el usuario, sus comidas, nevera, registros físicos, chats, recetas y alimentos personalizados. Un admin no puede borrar su propia cuenta desde aquí.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Cuenta eliminada
 *       404:
 *         description: Usuario no encontrado
 *       409:
 *         description: Un admin no puede borrar su propia cuenta (code CANNOT_DELETE_SELF)
 */
router.delete('/users/:userId', authenticateToken(['ADMIN']), validateUserIdParam, deleteUser);

export default router;
