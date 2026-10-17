import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { addGlass, getHistory, importHistory, undoGlass } from './hydration.controller.js';
import { validateDayBody, validateImportBody } from './hydration.validation.js';

const router = Router();
const auth = authenticateToken(['USER', 'ADMIN']);

/**
 * @openapi
 * /api/v1/hydration:
 *   get:
 *     tags: [Hydration]
 *     summary: Historial de vasos de agua del usuario
 *     description: 'data = { goal, history: { "YYYY-MM-DD": vasos } }. La app calcula la racha.'
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Historial }
 */
router.get('/', auth, getHistory);

/**
 * @openapi
 * /api/v1/hydration/glass:
 *   post:
 *     tags: [Hydration]
 *     summary: Suma un vaso al día (tope 4)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { type: object, required: [date], properties: { date: { type: string, example: '2026-10-17' } } }
 *     responses:
 *       200: { description: '{ date, glasses }' }
 */
router.post('/glass', auth, validateDayBody, addGlass);

/**
 * @openapi
 * /api/v1/hydration/glass/undo:
 *   post:
 *     tags: [Hydration]
 *     summary: Deshace el último vaso del día
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: '{ date, glasses }' }
 */
router.post('/glass/undo', auth, validateDayBody, undoGlass);

/**
 * @openapi
 * /api/v1/hydration/import:
 *   post:
 *     tags: [Hydration]
 *     summary: Sube el historial que estaba guardado en el teléfono
 *     description: Por cada día se queda el mayor valor entre el teléfono y el servidor.
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: '{ imported }' }
 */
router.post('/import', auth, validateImportBody, importHistory);

export default router;
