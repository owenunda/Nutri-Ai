import { Router } from 'express';
import authenticateToken, { rejectGuests } from '../../middleware/auth.middleware.js';
import { subscriptionSyncRateLimit } from '../../middleware/rateLimit.middleware.js';
import { receiveWebhook, syncSubscription } from './subscription.controller.js';
import { verifyWebhookAuth } from './webhookAuth.middleware.js';

const router = Router();

/**
 * @swagger
 * /api/v1/subscription/webhook:
 *   post:
 *     tags: [Subscription]
 *     summary: Webhook de RevenueCat
 *     description: >
 *       Sin JWT. El header Authorization debe ser igual a REVENUECAT_WEBHOOK_AUTH.
 *       Sincroniza a los usuarios del evento leyendo su estado real en RevenueCat.
 *     responses:
 *       200:
 *         description: Procesado ({ synced })
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       502:
 *         description: RevenueCat no respondió (SUBSCRIPTION_PROVIDER_ERROR). RevenueCat reintenta.
 */
router.post('/webhook', verifyWebhookAuth, receiveWebhook);

/**
 * @swagger
 * /api/v1/subscription/sync:
 *   post:
 *     tags: [Subscription]
 *     summary: Sincroniza la suscripción del usuario autenticado
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Plan efectivo ({ plan, proUntil, proSource })
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       429:
 *         description: Límite por minuto (RATE_LIMIT_EXCEEDED)
 *       502:
 *         description: RevenueCat no respondió (SUBSCRIPTION_PROVIDER_ERROR)
 */
router.post('/sync', authenticateToken(['USER', 'ADMIN']), rejectGuests, subscriptionSyncRateLimit, syncSubscription);

export default router;
