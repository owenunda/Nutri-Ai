import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { getProfile, updateProfile } from './user.controller.js';
import { validateUpdateProfileRequest } from './user.validation.js';

const router = Router();

router.get('/profile', authenticateToken(), getProfile);
router.put('/profile', authenticateToken(), validateUpdateProfileRequest, updateProfile);

export default router;
