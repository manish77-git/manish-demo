import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { createProfile, getProfile, getPublicProfile } from '../controllers/auth.controller.js';

const router = Router();

// All auth routes require authentication
router.post('/profile', authMiddleware, createProfile);
router.get('/profile', authMiddleware, getProfile);
router.get('/profile/:userId', getPublicProfile); // Public - no auth required

export default router;
