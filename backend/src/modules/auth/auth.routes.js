import { Router } from 'express';
import { getAuthHealth } from './auth.controller.js';
import { validateAuthHealthRequest } from './auth.validation.js';

const router = Router();

router.get('/health', validateAuthHealthRequest, getAuthHealth);

export default router;
