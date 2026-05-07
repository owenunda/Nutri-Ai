import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import { createPhysical, getProfile, updateProfile } from './user.controller.js';
import {
  validateCreatePhysicalRecordRequest,
  validateUpdateProfileRequest,
} from './user.validation.js';

const router = Router();

router.get('/profile', authenticateToken(), getProfile);
router.post('/physical', authenticateToken(), validateCreatePhysicalRecordRequest, createPhysical);
router.put('/profile', authenticateToken(), validateUpdateProfileRequest, updateProfile);

export default router;
