import { Router } from 'express';
import {
  forgotPasswordController,
  getAuthHealth,
  googleLink,
  googleLogin,
  guestLogin,
  login,
  register,
  resendVerificationController,
  resetPasswordController,
  verifyEmailController,
} from './auth.controller.js';
import {
  validateAuthHealthRequest,
  validateEmailOnlyRequest,
  validateResetPasswordRequest,
  validateVerifyEmailRequest,
  validateGoogleLinkRequest,
  validateGoogleLoginRequest,
  validateLoginRequest,
  validateRegisterRequest,
} from './auth.validation.js';
import { guestRateLimit, strictAuthRateLimit } from '../../middleware/rateLimit.middleware.js';

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
 *         description: Correo o contraseña inválidos
 */
router.post('/login', strictAuthRateLimit, validateLoginRequest, login);

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
router.post('/register', strictAuthRateLimit, validateRegisterRequest, register);

/**
 * @openapi
 * /api/v1/auth/google:
 *   post:
 *     tags: [Auth]
 *     summary: Iniciar sesión o registrarse con Google
 *     description: Verifica el idToken de Google. Si el sub ya está vinculado, inicia sesión; si existe una cuenta con el mismo email verificado, la vincula; si no, crea una cuenta sin contraseña.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [idToken]
 *             properties:
 *               idToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login exitoso. needsProfileSetup es true si el usuario no ha completado su perfil (edad).
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
 *                         needsProfileSetup:
 *                           type: boolean
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         description: idToken inválido (code INVALID_GOOGLE_TOKEN)
 *       403:
 *         description: Email de Google no verificado (code GOOGLE_EMAIL_NOT_VERIFIED)
 *       409:
 *         description: El email ya está vinculado a otra cuenta de Google (code GOOGLE_ACCOUNT_CONFLICT), o ya tiene una cuenta con contraseña y hay que vincularla con POST /auth/google/link (code GOOGLE_LINK_REQUIRES_PASSWORD)
 *       429:
 *         description: Demasiados intentos
 */
router.post('/google', strictAuthRateLimit, validateGoogleLoginRequest, googleLogin);

/**
 * @openapi
 * /api/v1/auth/google/link:
 *   post:
 *     tags: [Auth]
 *     summary: Vincular Google a una cuenta existente confirmando su contraseña
 *     description: Se usa cuando POST /auth/google responde GOOGLE_LINK_REQUIRES_PASSWORD. El idToken prueba que el correo es de quien entra y la contraseña que la cuenta es suya. La contraseña se conserva.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [idToken, password]
 *             properties:
 *               idToken:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cuenta vinculada; misma respuesta que POST /auth/google
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         description: idToken inválido (code INVALID_GOOGLE_TOKEN) o contraseña incorrecta (code INVALID_PASSWORD)
 *       403:
 *         description: Email de Google no verificado (code GOOGLE_EMAIL_NOT_VERIFIED)
 *       404:
 *         description: No hay ninguna cuenta con ese correo (code USER_NOT_FOUND)
 *       409:
 *         description: El email ya está vinculado a otra cuenta de Google (code GOOGLE_ACCOUNT_CONFLICT)
 *       429:
 *         description: Demasiados intentos
 */
router.post('/google/link', strictAuthRateLimit, validateGoogleLinkRequest, googleLink);

/**
 * @openapi
 * /api/v1/auth/guest:
 *   post:
 *     tags: [Auth]
 *     summary: Crea una cuenta de invitado temporal (24 h) con datos de ejemplo
 *     security: []
 *     responses:
 *       201:
 *         description: Sesión de invitado (token, user con isGuest y guestExpiresAt)
 *       404:
 *         description: El modo invitado está apagado (code GUEST_MODE_DISABLED)
 *       429:
 *         description: Demasiadas cuentas de invitado desde esta IP
 */
router.post('/guest', guestRateLimit, guestLogin);

/**
 * @openapi
 * /api/v1/auth/verify-email:
 *   post:
 *     tags: [Auth]
 *     summary: Verificar el correo con el código enviado
 *     description: Marca el correo como verificado y devuelve la sesión (misma respuesta que /auth/login).
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, code]
 *             properties:
 *               email: { type: string, format: email }
 *               code: { type: string, example: '482913' }
 *     responses:
 *       200:
 *         description: Correo verificado; incluye token, user y needsProfileSetup
 *       400:
 *         description: Código incorrecto (INVALID_CODE) o vencido (CODE_EXPIRED)
 *       429:
 *         description: Demasiados intentos
 */
router.post('/verify-email', strictAuthRateLimit, validateVerifyEmailRequest, verifyEmailController);

/**
 * @openapi
 * /api/v1/auth/verify-email/resend:
 *   post:
 *     tags: [Auth]
 *     summary: Reenviar el código de verificación
 *     description: Siempre responde 200 (no revela si el correo existe), salvo 429 si se pidió hace menos de un minuto.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200:
 *         description: Si el correo tiene una cuenta sin verificar, se envió un código
 *       429:
 *         description: Código enviado hace menos de un minuto (CODE_RECENTLY_SENT) o demasiados intentos
 */
router.post('/verify-email/resend', strictAuthRateLimit, validateEmailOnlyRequest, resendVerificationController);

/**
 * @openapi
 * /api/v1/auth/password/forgot:
 *   post:
 *     tags: [Auth]
 *     summary: Pedir un código para restablecer la contraseña
 *     description: Siempre responde 200 (no revela si el correo existe), salvo 429 si se pidió hace menos de un minuto.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200:
 *         description: Si el correo tiene una cuenta, se envió un código
 *       429:
 *         description: Código enviado hace menos de un minuto (CODE_RECENTLY_SENT) o demasiados intentos
 */
router.post('/password/forgot', strictAuthRateLimit, validateEmailOnlyRequest, forgotPasswordController);

/**
 * @openapi
 * /api/v1/auth/password/reset:
 *   post:
 *     tags: [Auth]
 *     summary: Restablecer la contraseña con el código enviado
 *     description: También marca el correo como verificado.
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, code, password]
 *             properties:
 *               email: { type: string, format: email }
 *               code: { type: string, example: '482913' }
 *               password: { type: string, minLength: 6 }
 *     responses:
 *       200:
 *         description: Contraseña restablecida
 *       400:
 *         description: Código incorrecto (INVALID_CODE) o vencido (CODE_EXPIRED)
 *       429:
 *         description: Demasiados intentos
 */
router.post('/password/reset', strictAuthRateLimit, validateResetPasswordRequest, resetPasswordController);

export default router;
