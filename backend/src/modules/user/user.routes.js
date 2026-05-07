import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { createPhysical, getProfile } from './user.controller.js';
import { validateCreatePhysicalRecordRequest } from './user.validation.js';

const router = Router();

router.get('/profile', authenticateToken(), getProfile);
router.post('/physical', authenticateToken(), validateCreatePhysicalRecordRequest, createPhysical);

export default router;
