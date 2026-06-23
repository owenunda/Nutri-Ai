import { Router } from 'express';
import { getAuthHealth, login, register } from './auth.controller.js';
import {
  validateAuthHealthRequest,
  validateLoginRequest,
  validateRegisterRequest,
} from './auth.validation.js';

const router = Router();

/**
 * @openapi
 * /api/v1/auth/health:
 *   get:
 *     tags: [Auth]
 *     summary: Estado del módulo de autenticación
 *     security: []
 *     responses:
 *       200:
 *         description: Módulo activo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiResponse'
 */
router.get('/health', validateAuthHealthRequest, getAuthHealth);

/**
 * @openapi
 * /api/v1/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Iniciar sesión
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: usuario@ejemplo.com
 *               password:
 *                 type: string
 *                 example: miContrasena123
 *     responses:
 *       200:
 *         description: Login exitoso, retorna token JWT y datos del usuario
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
 *                         token:
 *                           type: string
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       401:
 *         description: Contraseña incorrecta
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.post('/login', validateLoginRequest, login);

/**
 * @openapi
 * /api/v1/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Registrar nuevo usuario
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Juan Pérez
 *               email:
 *                 type: string
 *                 format: email
 *                 example: juan@ejemplo.com
 *               password:
 *                 type: string
 *                 example: miContrasena123
 *               goal:
 *                 type: string
 *                 example: perder peso
 *     responses:
 *       201:
 *         description: Usuario creado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/User'
 *       409:
 *         description: El email ya está registrado
 */
router.post('/register', validateRegisterRequest, register);

export default router;
