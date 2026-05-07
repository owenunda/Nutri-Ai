import { Router } from 'express';
import authenticateToken from '../../middleware/auth.middleware.js';
import {
  createPhysical,
  getPhysicalHistoryController,
  getProfile,
  updateProfile,
} from './user.controller.js';
import {
  validateCreatePhysicalRecordRequest,
  validateUpdateProfileRequest,
} from './user.validation.js';

const router = Router();

router.get('/profile', authenticateToken(), getProfile);
router.get('/physical/history', authenticateToken(), getPhysicalHistoryController);
router.post('/physical', authenticateToken(), validateCreatePhysicalRecordRequest, createPhysical);
router.put('/profile', authenticateToken(), validateUpdateProfileRequest, updateProfile);

export default router;
