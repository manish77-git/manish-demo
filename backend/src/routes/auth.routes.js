import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import {
  createProfile,
  getProfile,
  getPublicProfile,
  checkUsername,
  saveSinglePlayerHighScore,
  updateProfile,
  recordMatchResult,
} from '../controllers/auth.controller.js';

const router = Router();

router.get('/check-username', checkUsername);
router.post('/profile', authMiddleware, createProfile);
router.get('/profile', authMiddleware, getProfile);
router.patch('/profile', authMiddleware, updateProfile);
router.post('/singleplayer-score', authMiddleware, saveSinglePlayerHighScore);
router.post('/match-result', authMiddleware, recordMatchResult);
router.get('/profile/:userId', getPublicProfile);

export default router;
