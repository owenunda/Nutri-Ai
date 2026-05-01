import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getProfile } from './user.controller.js';

const router = Router();

router.get('/profile', authenticateToken(), getProfile);

export default router;
