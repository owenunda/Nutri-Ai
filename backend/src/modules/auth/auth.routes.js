import { Router } from 'express';
import { getAuthHealth, login } from './auth.controller.js';
import { validateAuthHealthRequest, validateLoginRequest } from './auth.validation.js';

const router = Router();

router.get('/health', validateAuthHealthRequest, getAuthHealth);
router.post('/login', validateLoginRequest, login);

export default router;
