import { Router } from 'express';
import { getAuthHealth, login, register } from './auth.controller.js';
import {
  validateAuthHealthRequest,
  validateLoginRequest,
  validateRegisterRequest,
} from './auth.validation.js';

const router = Router();

router.get('/health', validateAuthHealthRequest, getAuthHealth);
router.post('/login', validateLoginRequest, login);
router.post('/register', validateRegisterRequest, register);

export default router;
